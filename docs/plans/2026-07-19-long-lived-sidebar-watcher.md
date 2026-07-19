# Long-Lived Per-Socket Herdr Sidebar Watcher

## Intent

Replace the 50ms Bash polling loop with one long-lived Node process per Herdr API socket.

The current watcher works functionally, but every poll spawns `herdr`, two `jq` processes, and `sleep`: roughly 80 process launches per second at 50ms. The persistent Bash parent was observed around 2% of one CPU core and 6.7 MiB RSS; short-lived children and Herdr server work are additional. The goal is to preserve the verified collapse behavior while eliminating steady-state process churn.

## Current verified behavior

Repository: `/Users/iurysouza/projects/my-repos/pi-ghost-in-the-machine`

Published package commit before this refactor: `f67b503f818d3ac39f46251fc748f2811f423a17`.

The current implementation already proves:

- one Bash watcher is auto-started by Pi inside Herdr;
- default poll interval is 50ms;
- expanded Herdr layout reports `area.x = 36` on this Mac;
- compact collapsed layout reports `area.x = 4`;
- collapse sets the ghost to `off`;
- lifecycle updates remain gated to `off` while collapsed;
- expansion restores the focused Pi pane's latest state;
- the watcher logs transitions under `~/.local/state/ghost-in-the-machine/sidebar-watch.log`.

Keep all of those semantics.

## Herdr protocol facts

Herdr 0.7.4 exposes no sidebar visibility event. The workaround must still poll pane geometry.

Herdr's API socket uses newline-delimited JSON:

```json
{"id":"ghost-sidebar:1","method":"pane.layout","params":{}}
```

The response contains:

```text
.result.layout.area.x
.result.layout.area.width
```

Relevant Herdr source:

- `src/api/client.rs`: `ApiClient::request_value` connects, writes one JSON line, and reads one JSON line.
- `src/api/server.rs`: `handle_connection` reads one non-subscription request, writes one response, then closes.
- `src/api/schema.rs`: method name is `pane.layout`.
- `src/api/schema/panes.rs`: `PaneLayoutParams` accepts an optional `pane_id`; `{}` means current.

Therefore the new watcher should be a persistent **process**, but it must open a short Unix socket connection for each poll. Do not attempt to reuse one connection for repeated `pane.layout` requests; Herdr closes it after one response.

This Mac currently has one Herdr server/API socket:

```text
/Users/iurysouza/.config/herdr/herdr.sock
```

`herdr-client.sock` belongs to the same server and is not a second watcher target.

## Proposed architecture

### 1. Add a long-lived Node watcher

Add `scripts/sidebar-watcher.mjs` using only Node built-ins:

- `node:net` for Unix socket requests;
- `node:fs` / `node:path` for logs and runtime state;
- `node:child_process` only when a sidebar transition must call the controller;
- `node:crypto` for a stable socket key if needed.

Node 22.19+ is already required by `package.json`; add no runtime dependency.

At startup:

1. Resolve the API socket from `HERDR_SOCKET_PATH`.
2. If absent, fall back to `${XDG_CONFIG_HOME:-$HOME/.config}/herdr/herdr.sock`.
3. Resolve the controller from `GHOST_CONTROLLER_PATH` or the package-relative `scripts/ghost-state.sh`.
4. Poll every `SIDEBAR_POLL_INTERVAL`, default `0.05` seconds.
5. Never overlap polls: await the current request, then wait until the next scheduled interval.

For each poll:

1. Open the Unix socket.
2. Send one newline-terminated `pane.layout` request with a monotonically increasing request id.
3. Read through the first newline with a bounded timeout.
4. Parse JSON in-process.
5. Classify `area.x <= 4` as `collapsed`, otherwise `expanded`.
6. On state transition only, spawn:
   - `bash ghost-state.sh sidebar collapsed`, or
   - `bash ghost-state.sh sidebar expanded`.
7. Log transition, action result, socket path, request latency, and errors.

After 100 consecutive failures, log the reason and exit, preserving current behavior.

Keep the current hidden/mobile ambiguity documented. Do not invent heuristics beyond the verified `area.x` rule in this refactor.

### 2. Enforce one watcher per unique Herdr socket

The current global `sidebar-watch.pid` is insufficient for multiple Herdr sessions.

Key watcher runtime files by canonical socket path:

```text
~/.local/state/ghost-in-the-machine/watchers/<socket-key>/
  socket-path
  watcher.pid
  watcher.log
  start.lock/
```

Requirements:

- Same socket + repeated `watch-start` returns the existing live PID.
- Different sockets can start separate watcher processes.
- PID validation checks both liveness and expected watcher command.
- `watch-stop` stops only the watcher for the current `HERDR_SOCKET_PATH`.
- Add `watch-stop-all` only if tests or migration require it; avoid unnecessary CLI surface.
- `status` reports the current socket and watcher state.

Use the canonical absolute socket path as identity. Hash it for the directory name, but store the readable path in `socket-path` for diagnosis.

On this Mac, one API socket means one watcher.

### 3. Preserve controller semantics

Keep `scripts/ghost-state.sh` as the authority for:

- per-pane Pi lifecycle state;
- `sidebar.state` gating;
- global active shader selection;
- Ghostty config reload via `SIGUSR2`;
- collapse race reconciliation.

The Node watcher should not write Ghostty config or pane state itself. It only detects sidebar transitions and invokes the controller.

Spawning Bash on a transition is acceptable: transitions are rare. The performance problem is spawning processes on every poll.

### 4. Replace the Bash loop safely

Preferred migration:

- Replace `scripts/watch-sidebar.sh` with a small compatibility wrapper that `exec`s Node and the new `.mjs` file, or update all callers and remove it.
- Update `WATCHER` in `ghost-state.sh` to the final entrypoint.
- Keep `GHOST_SIDEBAR_WATCHER_PATH` test override.
- Keep Pi `session_start -> watch-start` unchanged conceptually.
- Keep `scripts/setup.sh -> watch-start`.
- Update README and engineering docs to describe a long-lived per-socket Node watcher rather than a Bash/CLI/JQ loop.
- Remove `jq` from watcher requirements, but retain it if `ghost-state.sh` still needs it for pane/focus parsing.

## Correctness requirements

- Collapse must hide the ghost within the configured poll interval plus one local socket request.
- A Pi lifecycle state written while collapsed must update pane memory but leave active shader `off`.
- Expand must restore the focused Pi pane's newest remembered state.
- `pane.focused` and sidebar transitions may race; `sidebar.state` remains the final visibility gate.
- Starting the same socket watcher concurrently must produce one process.
- Stale PID/lock files must recover without killing unrelated processes.
- A watcher must not target `herdr-client.sock`.
- Direct Pi sessions outside Herdr must not start a watcher.

## Tests

### Unit/integration tests in this repository

Add a fake Unix socket server in Node tests that:

- accepts one newline-delimited JSON request per connection;
- asserts `method === "pane.layout"` and `params === {}`;
- returns expanded and collapsed geometry;
- can delay, return malformed JSON, return API errors, and close early.

Test:

1. request framing and response parsing;
2. no overlapping requests;
3. transition deduplication;
4. collapse/expand controller invocations;
5. 100-failure exit behavior with a test-configurable lower threshold;
6. one singleton for the same socket;
7. distinct singleton identities for two socket paths;
8. stale PID and lock recovery;
9. paths containing spaces;
10. graceful SIGTERM and PID cleanup.

Retain the existing controller test proving collapsed lifecycle states remain `off`.

### Live verification

Using the installed Herdr session:

1. Stop the current Bash watcher.
2. Start the new watcher from the local package.
3. Start it twice and prove the PID is unchanged.
4. Toggle `Ctrl-A, b` to collapse.
5. Verify `area.x = 4`, `active=off`, and watcher log transition.
6. Request `working` or `done` while collapsed; verify `active=off`.
7. Expand; verify `area.x = 36` and latest state restored.
8. Stop/restart watcher and leave sidebar expanded.
9. Confirm one watcher for `HERDR_SOCKET_PATH` and no steady-state `herdr`/`jq` child churn.

## Performance acceptance

Measure old Bash watcher versus new Node watcher over equal idle windows, with production restored afterward.

Report:

- persistent process RSS;
- watcher CPU time / `%CPU`;
- Herdr server CPU-time delta;
- process launches during steady-state polling;
- average and max socket request latency;
- observed polls per second.

Expected outcome:

- zero `herdr`, `jq`, or `sleep` process launches per steady-state poll;
- one persistent Node watcher per API socket;
- materially lower CPU/wakeup cost than the Bash implementation;
- potentially higher stable RSS than Bash, accepted if CPU/process churn drops substantially.

Do not claim a numeric improvement without measuring it.

## Release and migration

After implementation and verification:

1. Run `npm run check`, `npm test`, and `npm pack --dry-run`.
2. Commit the package changes using the repository's commit conventions.
3. Push the public `iurysza/pi-ghost-in-the-machine` repository.
4. Update `/Users/iurysouza/dev/personal/tools/agents/dependencies.json` to the new immutable commit.
5. Commit only that intended agents-repo file; preserve unrelated untracked artifacts.
6. Run the canonical agents installer with dependencies enabled.
7. Stop the local-development watcher.
8. Start and verify the watcher from `~/.pi/agent/git/github.com/iurysza/pi-ghost-in-the-machine`.
9. Leave the sidebar expanded and the installed watcher running.
10. Tell the user whether `/reload` is needed for the current Pi process.

## Non-goals

- No Herdr upstream changes.
- No sidebar event implementation.
- No shader visual changes.
- No Ghostty signaling redesign.
- No multi-socket arbitration redesign for Ghostty's global shader config.

## Unresolved questions

- Multi-socket watchers can contend for one global Ghostty shader config; defer arbitration because this Mac has one Herdr API socket.
- Keep 50ms for behavioral parity; revisit only after measured performance.
