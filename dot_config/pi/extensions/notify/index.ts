/**
 * notify — desktop notification when Pi finishes a run while the
 * terminal window is unfocused.
 *
 * Focus detection uses the standard X10 focus-in/focus-out escape sequences:
 * the extension enables focus reporting (`ESC [ ? 1004 h`) and tracks the
 * `ESC [ I` (focus in) / `ESC [ O` (focus out) sequences on stdin. Pi's TUI
 * already enables this mode, and most modern terminals (iTerm2, GNOME
 * Terminal, Kitty, Alacritty, WezTerm, foot, Windows Terminal) send the
 * events.
 *
 * Semantics:
 *   - If the last observed state was "focused", no notification is sent.
 *   - If no focus event has been seen yet (unknown state — e.g. the terminal
 *     doesn't report focus), a notification IS sent: if the user is away,
 *     that is exactly when the notification is wanted.
 *
 * Notifications use the OSC 777 escape sequence, which the terminal renders
 * as a native desktop notification (supported by Ghostty, iTerm2, WezTerm,
 * rxvt-unicode). Terminals without support simply ignore the sequence.
 */

import { basename } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

/** ASCII escape introducer (0x1B), starting all ANSI/VT sequences. */
const ESC = "\x1b";

/** OSC 777 terminal notification: the terminal shows a desktop notification. */
const TERMINAL_NOTIFY = (title: string, body: string) =>
  `${ESC}]777;notify;${title};${body}\x07`;

/** X10 focus-in sequence the terminal sends on stdin when the window gains focus. */
const FOCUS_IN = `${ESC}[I`;

/** X10 focus-out sequence the terminal sends on stdin when the window loses focus. */
const FOCUS_OUT = `${ESC}[O`;

/** Enable X10 focus reporting (private mode 1004); makes the terminal emit FOCUS_IN/FOCUS_OUT. */
const ENABLE_FOCUS_REPORTING = `${ESC}[?1004h`;

/** Disable X10 focus reporting on shutdown so the terminal stops sending focus events. */
const DISABLE_FOCUS_REPORTING = `${ESC}[?1004l`;

/** Max characters to buffer while waiting for a focus sequence. */
const MAX_PENDING_CHARS = 4_096;

export default function (pi: ExtensionAPI) {
  let ctx: ExtensionContext | undefined;

  /** true = focused, false = unfocused, undefined = unknown */
  let focused: boolean | undefined;

  /** stdin listener attached (focus reporting enabled). */
  let attached = false;

  /** Characters buffered while waiting for a focus sequence. */
  let pending = "";

  const onStdinData = (chunk: Buffer | string) => {
    pending += chunk.toString();

    for (;;) {
      const inIdx = pending.indexOf(FOCUS_IN);
      const outIdx = pending.indexOf(FOCUS_OUT);
      if (inIdx === -1 && outIdx === -1) {
        break;
      }
      if (inIdx !== -1 && (outIdx === -1 || inIdx < outIdx)) {
        focused = true;
        pending = pending.slice(inIdx + FOCUS_IN.length);
      } else {
        focused = false;
        pending = pending.slice(outIdx + FOCUS_OUT.length);
      }
    }

    if (pending.length > MAX_PENDING_CHARS) {
      // Focus sequences are 3 chars; if the cut point would split one,
      // keep its trailing partial prefix ("\x1b" or "\x1b[") so the
      // sequence can still be matched once the rest arrives.
      const head = pending.slice(0, pending.length - MAX_PENDING_CHARS);
      const partial = head.endsWith(`${ESC}[`) ? 2 : head.endsWith(ESC) ? 1 : 0;
      pending = pending.slice(pending.length - (MAX_PENDING_CHARS + partial));
    }
  };

  const attach = (sessionCtx: ExtensionContext) => {
    ctx = sessionCtx;

    if (attached) {
      return;
    } // session switch: keep listener + focus state
    attached = true;

    // Best-effort: Pi's TUI normally enables focus reporting already;
    // this covers terminals where it doesn't. Only write to a real TTY.
    if (process.stdout.isTTY) {
      process.stdout.write(ENABLE_FOCUS_REPORTING);
    }

    process.stdin.on("data", onStdinData);
  };

  const detach = () => {
    ctx = undefined;

    if (!attached) {
      return;
    }
    attached = false;
    focused = undefined;
    pending = "";

    process.stdin.off("data", onStdinData);

    if (process.stdout.isTTY) {
      process.stdout.write(DISABLE_FOCUS_REPORTING);
    }
  };

  pi.on("session_start", (_event, sessionCtx) => {
    if (!sessionCtx.hasUI) {
      return;
    } // interactive mode only
    attach(sessionCtx);
  });

  pi.on("session_shutdown", () => {
    detach();
  });

  const processCwdName = basename(process.cwd());

  pi.on("agent_settled", (event) => {
    if (event.aborted || !ctx) {
      return;
    }
    if (focused === true) {
      return;
    } // user is watching

    const cwdName = basename(ctx.cwd);
    const suffix = cwdName === processCwdName ? "" : ` in ${cwdName}`;

    process.stdout.write(
      TERMINAL_NOTIFY(`Pi: Agent finished${suffix}`, "Waiting for input."),
    );
  });
}
