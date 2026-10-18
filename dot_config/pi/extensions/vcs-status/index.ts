/**
 * vcs-status — shows the current change in the footer status bar, for
 * Jujutsu and Git repositories.
 *
 *   Jujutsu: <change id> <commit id> <nearest bookmark>[+N] <flags> <+added −removed> <description>
 *   Git:     <branch> <commit> <↑ahead ↓behind> <state> <+added −removed ?untracked> <subject>
 *
 * Jujutsu wins in colocated repositories. In a Jujutsu bookmark, `*` marks
 * one that differs from its remote and `+N` how many commits @ sits above it.
 *
 * The status refreshes after each tool call, when a run settles, and on a
 * short idle poll so changes made outside Pi show up too.
 *
 * Running `jj` snapshots the working copy, which rewrites @. Doing that while
 * the agent may be running `jj` itself risks a divergent change, so during a
 * run the extension passes `--ignore-working-copy` and shows the change as of
 * the last snapshot; the diff stats catch up once the run settles.
 */

import { existsSync } from "node:fs";
import { join } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "vcs";
const POLL_MS = 5_000;
const DEBOUNCE_MS = 200;
const EXEC_TIMEOUT_MS = 5_000;
const DESCRIPTION_CHARS = 48;
// Stop counting commits between @ and its nearest bookmark past this.
const MAX_DISTANCE = 99;

const SEP = "\x1f";

const JJ_TEMPLATE = [
  "change_id.shortest(8).prefix()",
  "change_id.shortest(8).rest()",
  "commit_id.shortest(8)",
  "description.first_line()",
  "empty",
  "conflict",
  "divergent",
  "self.diff().files().len()",
  "self.diff().stat().total_added()",
  "self.diff().stat().total_removed()",
].join(` ++ "${SEP}" ++ `);

const JJ_BOOKMARKS_TEMPLATE =
  'local_bookmarks.map(|b| b.name() ++ if(!b.synced(), "*")).join(" ") ++ "\\n"';

interface JjStatus {
  kind: "jj";
  changePrefix: string;
  changeRest: string;
  commit: string;
  description: string;
  empty: boolean;
  conflict: boolean;
  divergent: boolean;
  files: number;
  added: number;
  removed: number;
  bookmarks: string[];
  distance: number;
}

interface GitStatus {
  kind: "git";
  branch: string | undefined;
  commit: string | undefined;
  subject: string;
  ahead: number;
  behind: number;
  state: string | undefined;
  files: number;
  untracked: number;
  conflicts: number;
  added: number;
  removed: number;
}

type VcsStatus = JjStatus | GitStatus;

// Marker files in the Git directory for operations in progress, in priority order.
const GIT_STATES: [string, string][] = [
  ["rebase-merge", "rebasing"],
  ["rebase-apply", "rebasing"],
  ["MERGE_HEAD", "merging"],
  ["CHERRY_PICK_HEAD", "cherry-picking"],
  ["REVERT_HEAD", "reverting"],
  ["BISECT_LOG", "bisecting"],
];

function truncate(text: string, max: number): string {
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

export default function (pi: ExtensionAPI) {
  let ctx: ExtensionContext | undefined;
  let agentRunning = false;
  let poll: NodeJS.Timeout | undefined;
  let debounce: NodeJS.Timeout | undefined;
  let inFlight = false;
  let pending = false;
  let abort: AbortController | undefined;
  // Last text set, to avoid redundant footer redraws.
  let shown: string | undefined;

  const run = async (
    cmd: string,
    args: string[],
    cwd: string,
    signal: AbortSignal,
  ) => {
    const result = await pi.exec(cmd, args, {
      cwd,
      signal,
      timeout: EXEC_TIMEOUT_MS,
    });
    return result.code === 0 && !result.killed ? result.stdout : undefined;
  };

  const readJj = async (
    cwd: string,
    signal: AbortSignal,
  ): Promise<JjStatus | undefined> => {
    const jj = (args: string[], snapshot = false) =>
      run(
        "jj",
        [
          ...args,
          "--no-graph",
          "--color=never",
          ...(snapshot ? [] : ["--ignore-working-copy"]),
        ],
        cwd,
        signal,
      );

    // Snapshot first (when allowed) so the follow-up queries see the same @.
    const main = await jj(["log", "-r", "@", "-T", JJ_TEMPLATE], !agentRunning);
    if (main === undefined) return;
    const [
      changePrefix,
      changeRest,
      commit,
      description,
      empty,
      conflict,
      divergent,
      files,
      added,
      removed,
    ] = main.split(SEP);

    const [bookmarks, distance] = await Promise.all([
      jj([
        "log",
        "-r",
        "heads(::@ & bookmarks())",
        "-T",
        JJ_BOOKMARKS_TEMPLATE,
      ]),
      jj([
        "log",
        "-r",
        "heads(::@ & bookmarks())..@",
        "--limit",
        String(MAX_DISTANCE + 1),
        "-T",
        '"x"',
      ]),
    ]);

    return {
      kind: "jj",
      changePrefix,
      changeRest,
      commit,
      description,
      empty: empty === "true",
      conflict: conflict === "true",
      divergent: divergent === "true",
      files: Number(files) || 0,
      added: Number(added) || 0,
      removed: Number(removed) || 0,
      bookmarks: [...new Set(bookmarks?.split(/\s+/).filter(Boolean))],
      distance: distance?.length ?? 0,
    };
  };

  const readGit = async (
    cwd: string,
    gitDir: string,
    signal: AbortSignal,
  ): Promise<GitStatus | undefined> => {
    // --no-optional-locks keeps `git status` from taking index.lock to refresh
    // the index, which could make the agent's own git commands fail.
    const git = (args: string[]) =>
      run("git", ["--no-optional-locks", ...args], cwd, signal);

    const [status, log, diff] = await Promise.all([
      git(["status", "--porcelain=v2", "--branch", "--untracked-files=normal"]),
      git(["log", "-1", "--format=%h%x1f%s"]),
      git(["diff", "HEAD", "--numstat"]),
    ]);
    if (status === undefined) return;

    const result: GitStatus = {
      kind: "git",
      branch: undefined,
      commit: undefined,
      subject: "",
      ahead: 0,
      behind: 0,
      state: GIT_STATES.find(([file]) => existsSync(join(gitDir, file)))?.[1],
      files: 0,
      untracked: 0,
      conflicts: 0,
      added: 0,
      removed: 0,
    };

    for (const line of status.split("\n")) {
      if (line.startsWith("# branch.head ")) {
        const head = line.slice("# branch.head ".length);
        if (head !== "(detached)") result.branch = head;
      } else if (line.startsWith("# branch.ab ")) {
        const m = /\+(\d+) -(\d+)/.exec(line);
        if (m) {
          result.ahead = Number(m[1]);
          result.behind = Number(m[2]);
        }
      } else if (line.startsWith("1 ") || line.startsWith("2 ")) {
        result.files++;
      } else if (line.startsWith("u ")) {
        result.files++;
        result.conflicts++;
      } else if (line.startsWith("? ")) {
        result.untracked++;
      }
    }

    if (log) {
      const [commit, subject = ""] = log.trimEnd().split(SEP);
      result.commit = commit;
      result.subject = subject;
    }

    // Binary files report "-" for both counts.
    for (const line of diff?.split("\n") ?? []) {
      const [a, r] = line.split("\t");
      result.added += Number(a) || 0;
      result.removed += Number(r) || 0;
    }

    return result;
  };

  const read = async (
    cwd: string,
    signal: AbortSignal,
  ): Promise<VcsStatus | undefined> => {
    if (
      (await run("jj", ["root", "--ignore-working-copy"], cwd, signal)) !==
      undefined
    ) {
      return readJj(cwd, signal);
    }
    const gitDir = await run(
      "git",
      ["rev-parse", "--absolute-git-dir"],
      cwd,
      signal,
    );
    if (gitDir !== undefined) return readGit(cwd, gitDir.trim(), signal);
  };

  const format = (status: VcsStatus, c: ExtensionContext): string => {
    const t = c.ui.theme;
    const parts: string[] = [];
    const diffStat = (added: number, removed: number) =>
      `${t.fg("toolDiffAdded", `+${added}`)} ${t.fg("toolDiffRemoved", `−${removed}`)}`;

    if (status.kind === "jj") {
      parts.push(
        t.fg("accent", status.changePrefix) + t.fg("dim", status.changeRest),
        t.fg("muted", status.commit),
      );
      if (status.bookmarks.length > 0) {
        const distance =
          status.distance === 0
            ? ""
            : `+${status.distance > MAX_DISTANCE ? `${MAX_DISTANCE}+` : status.distance}`;
        parts.push(
          t.fg("syntaxType", status.bookmarks.join(" ")) +
            t.fg("dim", distance),
        );
      }
      if (status.conflict) parts.push(t.fg("error", "conflict"));
      if (status.divergent) parts.push(t.fg("warning", "divergent"));
      if (status.empty) {
        parts.push(t.fg("dim", "(empty)"));
      } else {
        parts.push(
          diffStat(status.added, status.removed) +
            t.fg("dim", ` ${status.files}f`),
        );
      }
      parts.push(
        status.description
          ? t.fg("muted", truncate(status.description, DESCRIPTION_CHARS))
          : t.fg("dim", "(no description)"),
      );
    } else {
      parts.push(
        status.branch
          ? t.fg("syntaxType", status.branch)
          : t.fg("warning", "detached"),
        t.fg("muted", status.commit ?? "(no commits)"),
      );
      const ab = [
        status.ahead && `↑${status.ahead}`,
        status.behind && `↓${status.behind}`,
      ].filter(Boolean);
      if (ab.length > 0) parts.push(t.fg("accent", ab.join("")));
      if (status.state) parts.push(t.fg("warning", status.state));
      if (status.conflicts > 0)
        parts.push(t.fg("error", `${status.conflicts} conflicted`));
      if (status.files > 0 || status.untracked > 0) {
        let changes = diffStat(status.added, status.removed);
        if (status.files > 0) changes += t.fg("dim", ` ${status.files}f`);
        if (status.untracked > 0)
          changes += t.fg("dim", ` ?${status.untracked}`);
        parts.push(changes);
      } else {
        parts.push(t.fg("dim", "(clean)"));
      }
      if (status.subject)
        parts.push(t.fg("muted", truncate(status.subject, DESCRIPTION_CHARS)));
    }

    return parts.join(" ");
  };

  const setStatus = (text: string | undefined) => {
    if (!ctx?.hasUI || text === shown) return;
    shown = text;
    ctx.ui.setStatus(STATUS_KEY, text);
  };

  const refresh = async () => {
    if (!ctx?.hasUI) return;
    if (inFlight) {
      pending = true;
      return;
    }
    inFlight = true;
    const current = ctx;
    abort ??= new AbortController();
    const signal = abort.signal;
    try {
      const status = await read(current.cwd, signal);
      // The session may have been replaced while the commands ran.
      if (ctx === current && !signal.aborted)
        setStatus(status && format(status, current));
    } catch {
      // Keep the last status; a transient failure (lock contention, timeout)
      // shouldn't blank it.
    } finally {
      inFlight = false;
      if (pending) {
        pending = false;
        schedule();
      }
    }
  };

  const schedule = () => {
    clearTimeout(debounce);
    debounce = setTimeout(() => void refresh(), DEBOUNCE_MS);
  };

  const stop = () => {
    clearInterval(poll);
    clearTimeout(debounce);
    poll = undefined;
    debounce = undefined;
    abort?.abort();
    abort = undefined;
    pending = false;
  };

  pi.on("session_start", (_event, sessionCtx) => {
    stop();
    ctx = sessionCtx;
    shown = undefined;
    agentRunning = false;
    if (!sessionCtx.hasUI) return;
    void refresh();
    poll = setInterval(() => void refresh(), POLL_MS);
    poll.unref();
  });

  pi.on("session_shutdown", () => {
    stop();
    if (ctx?.hasUI) ctx.ui.setStatus(STATUS_KEY, undefined);
    ctx = undefined;
    shown = undefined;
  });

  pi.on("agent_start", () => {
    agentRunning = true;
  });

  pi.on("agent_settled", () => {
    agentRunning = false;
    schedule();
  });

  pi.on("tool_execution_end", () => schedule());
}
