# Lifecycle and Data Flow

Automatic flow begins when Pi emits lifecycle events. Session start selects `idle`. User input and agent start select `thinking`. Bash, edit, and write tools select `working`; other tools remain `thinking`. A failed tool records an error for the current turn and selects `error`. Settlement selects `done` unless any tool failed, in which case `error` persists. Shutdown clears the pane and removes the shader.

These event edges often occur faster than Ghostty can reload and compile a large shader. The extension therefore holds each applied state for a minimum dwell. While one state is waiting or being applied, newer requests coalesce into the latest queued state. This preserves a visible progression without replaying every read/write alternation long after the turn ends.

A state request crosses from Pi into the controller. Outside Herdr, it becomes active immediately. Inside Herdr, the controller first records the request against the emitting pane. It changes Ghostty only if that pane is still focused. This second check matters because focus can move while a state write is in flight.

Activation rewrites the runtime fragment with the selected variant path, records the active state, and signals Ghostty with `SIGUSR2`. Ghostty reloads configuration, detects a changed `custom-shader` path, rebuilds the shader pipeline, and renders the forced state. `off` writes a fragment without a shader path, so the terminal returns to its unmodified render.

Focus flow enters through the Herdr plugin rather than Pi. On `pane.focused`, the controller asks Herdr which pane now owns focus. A Pi pane restores its remembered state. Any other pane selects `off`. Ghostty application focus adds another gate inside the shader through `iFocus`, hiding the face when the whole terminal surface is unfocused without changing semantic state.

Manual `/ghost-<state>` commands bypass lifecycle mapping but use the same controller and active-state path. `/ghost-off` is temporary: the next lifecycle event may show the ghost again. `/ghost-disable` suppresses automatic state changes for the current Pi session until `/ghost-on`.

See [[ai-artifacts/docs/semantic-map|the semantic map]] for desired, pane, and active state, and [[ai-artifacts/docs/operations-and-verification|operations]] for diagnosing where a transition stopped.
