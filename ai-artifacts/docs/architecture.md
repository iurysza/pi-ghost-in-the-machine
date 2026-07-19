# Architecture

The package is a narrow pipeline with four cooperating pieces.

The **Pi extension** is the lifecycle interpreter. It maps session, input, agent, and tool events into the ghost-state vocabulary. It also owns manual `/ghost-*` commands and a short dwell queue. The queue preserves visual legibility while coalescing redundant transitions; it is not a durable job queue.

The **state controller** is the boundary between semantic state and terminal integration. It remembers per-pane state, decides whether the focused Herdr pane is eligible, writes the current Ghostty fragment, and sends the reload signal. It deliberately contains no expression logic. Given a state, it selects a pre-generated shader path.

The **Ghostty config fragment** is a tiny runtime handoff. It contains either one `custom-shader` path or no shader for `off`. Changing the path matters because Ghostty reloads shader pipelines when configuration points somewhere new; editing shader contents in place is not a supported state channel. The fragment lives in stable user state so package updates may move source files without changing the main Ghostty include path.

The **shader family** is the render plane. One source defines geometry, expressions, decorations, motion, color, focus gating, and terminal compositing. Generation produces forced-state variants. Each variant is intentionally self-sufficient because Ghostty treats multiple `custom-shader` entries as a pipeline, not alternatives.

The **Herdr plugin** adds focus ownership. Pi sessions can update remembered state even while hidden, but only the focused Pi pane may project its state into Ghostty. Focusing another kind of pane removes the shader; returning restores that Pi pane’s last state.

These pieces communicate through deliberately boring boundaries: lifecycle callbacks, command execution, small state files, one config fragment, and `SIGUSR2`. No long-running daemon is required. The cost is that Ghostty recompiles on transitions, which makes [[ai-artifacts/docs/lifecycle-and-data-flow|dwell timing]] and [[ai-artifacts/docs/integration-boundaries|external guarantees]] architectural concerns rather than polish.
