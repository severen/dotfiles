/**
 * editor-context — tells the agent which file you have open in your editor and
 * where your cursor (or selection) is.
 *
 * Pi listens on a Unix socket and editors push their state to it, so any
 * editor that can open a socket (or shell out to `socat`) can take part:
 *
 *   $XDG_RUNTIME_DIR/pi-editor/<pi-pid>.sock
 *
 * Editors discover Pi instances by listing that directory and connecting to
 * every socket. A refused connection means a stale socket, which the editor
 * may delete. Sockets are recreated on session replacement (/new, /resume,
 * /fork), so editors should reconnect when a connection drops.
 *
 * Protocol: newline-delimited JSON, one object per line.
 *
 *   Pi → editor, on connect:
 *     {"type":"welcome","pid":1234,"cwd":"/home/me/proj"}
 *
 *   Editor → Pi:
 *     {"type":"hello","editor":"nvim","cwd":"/home/me/proj"}
 *     {"type":"state","file":"/home/me/proj/src/main.rs","line":42,"col":7,
 *      "selection":{"start":{"line":40,"col":1},"end":{"line":44,"col":12},"text":"..."}}
 *     {"type":"clear"}
 *
 *   Lines and columns are 1-based. `file` may be relative to the editor's cwd.
 *   `selection` is optional; `text` within it is optional. Send `clear` when
 *   the focused buffer isn't a file. Closing the connection also clears state.
 *
 * Pi ignores editors whose file and cwd both lie outside its own cwd. When
 * several editors are relevant, the most recently updated one wins.
 *
 * Before each prompt, if the editor state changed since it was last reported,
 * a hidden context message is added to the run. The `editor_context` tool lets
 * the model re-check mid-run. The footer shows what the agent will see.
 */

import { chmod, mkdir, unlink } from "node:fs/promises";
import { createServer, type Server, type Socket } from "node:net";
import { tmpdir, userInfo } from "node:os";
import { basename, isAbsolute, join, relative, resolve } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const SOCKET_DIR = process.env.XDG_RUNTIME_DIR
  ? join(process.env.XDG_RUNTIME_DIR, "pi-editor")
  : join(tmpdir(), `pi-editor-${userInfo().uid}`);

// Drop a connection that sends a line longer than this without a newline.
const MAX_LINE_BYTES = 1 << 20;
// Selection text included in the automatic per-prompt message vs. the tool.
const PROMPT_SELECTION_CHARS = 4_000;
const TOOL_SELECTION_CHARS = 32_000;

interface Position {
  line: number;
  col: number;
}

interface EditorState {
  file: string;
  line: number;
  col: number;
  selection?: { start: Position; end: Position; text?: string };
}

interface Editor {
  name: string;
  cwd?: string;
  state?: EditorState;
  updated: number;
}

function isPosition(v: unknown): v is Position {
  const p = v as Position;
  return (
    typeof p === "object" &&
    p !== null &&
    Number.isInteger(p.line) &&
    Number.isInteger(p.col)
  );
}

function parseState(
  msg: Record<string, unknown>,
  cwd: string | undefined,
): EditorState | undefined {
  const { file, line, col, selection } = msg;
  if (
    typeof file !== "string" ||
    file === "" ||
    !Number.isInteger(line) ||
    !Number.isInteger(col)
  ) {
    return;
  }
  const state: EditorState = {
    file: isAbsolute(file) || !cwd ? file : resolve(cwd, file),
    line: line as number,
    col: col as number,
  };
  const sel = selection as EditorState["selection"];
  if (sel && isPosition(sel.start) && isPosition(sel.end)) {
    state.selection = { start: sel.start, end: sel.end };
    if (typeof sel.text === "string") {
      state.selection.text = sel.text;
    }
  }
  return state;
}

function isWithin(path: string, dir: string): boolean {
  const rel = relative(dir, path);
  return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel));
}

function displayPath(file: string, cwd: string): string {
  return isWithin(file, cwd) ? relative(cwd, file) : file;
}

function truncate(text: string, max: number): string {
  return text.length <= max
    ? text
    : `${text.slice(0, max)}\n… [truncated ${text.length - max} characters]`;
}

function describe(
  editor: Editor,
  state: EditorState,
  cwd: string,
  maxSelection: number,
): string {
  const path = displayPath(state.file, cwd);
  const lines = [
    `The user's editor (${editor.name}) has ${path} open, cursor at line ${state.line}, column ${state.col}.`,
  ];
  const sel = state.selection;
  if (sel) {
    const range =
      sel.start.line === sel.end.line
        ? `line ${sel.start.line}, columns ${sel.start.col}–${sel.end.col}`
        : `lines ${sel.start.line}–${sel.end.line}`;
    if (sel.text) {
      lines.push(
        `They have selected ${range}:`,
        "```",
        truncate(sel.text, maxSelection),
        "```",
      );
    } else {
      lines.push(`They have selected ${range}.`);
    }
  }
  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  let server: Server | undefined;
  let socketPath: string | undefined;
  let ctx: ExtensionContext | undefined;
  const editors = new Map<Socket, Editor>();
  // Fingerprint of the state last added to the conversation.
  let lastReported: string | undefined;

  const isRelevant = (editor: Editor, cwd: string) =>
    editor.state !== undefined &&
    (isWithin(editor.state.file, cwd) ||
      (editor.cwd !== undefined && isWithin(editor.cwd, cwd)));

  const current = (cwd: string): Editor | undefined => {
    let best: Editor | undefined;
    for (const editor of editors.values()) {
      if (isRelevant(editor, cwd) && (!best || editor.updated > best.updated)) {
        best = editor;
      }
    }
    return best;
  };

  const updateStatus = () => {
    if (!ctx?.hasUI) {
      return;
    }
    const editor = current(ctx.cwd);
    const state = editor?.state;
    ctx.ui.setStatus(
      "editor",
      state
        ? `${editor.name} ${basename(state.file)}:${state.line}`
        : undefined,
    );
  };

  const handleMessage = (editor: Editor, raw: string) => {
    let msg: Record<string, unknown>;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }
    if (typeof msg !== "object" || msg === null) {
      return;
    }
    switch (msg.type) {
      case "hello":
        if (typeof msg.editor === "string" && msg.editor !== "") {
          editor.name = msg.editor;
        }
        if (typeof msg.cwd === "string" && isAbsolute(msg.cwd)) {
          editor.cwd = msg.cwd;
        }
        break;
      case "state": {
        const state = parseState(msg, editor.cwd);
        if (!state) {
          return;
        }
        editor.state = state;
        editor.updated = Date.now();
        break;
      }
      case "clear":
        editor.state = undefined;
        editor.updated = Date.now();
        break;
      default:
        return;
    }
    updateStatus();
  };

  const handleConnection = (socket: Socket) => {
    const editor: Editor = { name: "editor", updated: 0 };
    editors.set(socket, editor);
    socket.setEncoding("utf8");
    socket.write(
      `${JSON.stringify({ type: "welcome", pid: process.pid, cwd: ctx?.cwd })}\n`,
    );

    let buffer = "";
    socket.on("data", (chunk: string) => {
      buffer += chunk;
      let newline = buffer.indexOf("\n");
      while (newline !== -1) {
        const line = buffer.slice(0, newline).trim();
        buffer = buffer.slice(newline + 1);
        if (line) {
          handleMessage(editor, line);
        }
        newline = buffer.indexOf("\n");
      }
      if (buffer.length > MAX_LINE_BYTES) {
        socket.destroy();
      }
    });
    socket.on("error", () => socket.destroy());
    socket.on("close", () => {
      editors.delete(socket);
      updateStatus();
    });
  };

  const stop = async () => {
    const s = server;
    const path = socketPath;
    server = undefined;
    socketPath = undefined;
    for (const socket of editors.keys()) {
      socket.destroy();
    }
    editors.clear();
    if (s) {
      await new Promise<void>((done) => s.close(() => done()));
    }
    if (path) {
      await unlink(path).catch(() => {});
    }
  };

  pi.on("session_start", async (_event, sessionCtx) => {
    await stop();
    ctx = sessionCtx;
    lastReported = undefined;

    const path = join(SOCKET_DIR, `${process.pid}.sock`);
    try {
      await mkdir(SOCKET_DIR, { recursive: true, mode: 0o700 });
      // Only our own PID can own this path; anything there is left over.
      await unlink(path).catch(() => {});
      const s = createServer(handleConnection);
      await new Promise<void>((done, fail) => {
        s.once("error", fail);
        s.listen(path, () => {
          s.off("error", fail);
          done();
        });
      });
      await chmod(path, 0o600);
      s.on("error", () => {});
      server = s;
      socketPath = path;
    } catch (err) {
      if (sessionCtx.hasUI) {
        sessionCtx.ui.notify(
          `editor-context: could not listen on ${path}: ${(err as Error).message}`,
          "error",
        );
      }
    }
    updateStatus();
  });

  pi.on("session_shutdown", async () => {
    if (ctx?.hasUI) {
      ctx.ui.setStatus("editor", undefined);
    }
    ctx = undefined;
    await stop();
  });

  pi.on("before_agent_start", (event, runCtx) => {
    if (event.messageType !== "user") {
      return;
    }
    const editor = current(runCtx.cwd);
    const state = editor?.state;
    // Report a newly unfocused editor once, so the model doesn't keep
    // assuming the last position it was told about.
    const fingerprint = state ? JSON.stringify(state) : undefined;
    if (fingerprint === lastReported) {
      return;
    }
    const hadReported = lastReported !== undefined;
    lastReported = fingerprint;
    if (!editor || !state) {
      if (!hadReported) {
        return;
      }
      return {
        message: {
          customType: "editor-context",
          content:
            "<editor-context>\nThe user's editor no longer has a file in this project focused.\n</editor-context>",
          display: false,
        },
      };
    }
    return {
      message: {
        customType: "editor-context",
        content: `<editor-context>\n${describe(editor, state, runCtx.cwd, PROMPT_SELECTION_CHARS)}\n</editor-context>`,
        display: false,
        details: { editor: editor.name, ...state },
      },
    };
  });

  pi.registerTool({
    name: "editor_context",
    label: "Editor context",
    description:
      "Get the file the user currently has open in their editor, their cursor position, and any selected text. " +
      "Use when the user refers to 'this file', 'here', 'this function' or 'the selection', or when their " +
      "position may have changed since it was last reported.",
    promptSnippet:
      "Get the file, cursor position and selection in the user's editor",
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, _signal, _onUpdate, toolCtx) {
      const editor = current(toolCtx.cwd);
      const state = editor?.state;
      if (!editor || !state) {
        return {
          content: [
            {
              type: "text",
              text: "No editor is connected with a file in this project focused.",
            },
          ],
          details: undefined,
        };
      }
      return {
        content: [
          {
            type: "text",
            text: describe(editor, state, toolCtx.cwd, TOOL_SELECTION_CHARS),
          },
        ],
        details: { editor: editor.name, ...state },
      };
    },
  });
}
