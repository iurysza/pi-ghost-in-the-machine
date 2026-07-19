# Glossary

**Active state** — The state whose shader path Ghostty currently has configured. It may be `off` even while a hidden Pi pane desires another state.

**Control plane** — The extension, controller, state files, config fragment, focus routing, and reload signal that decide what Ghostty should render.

**Desired state** — The most recent lifecycle or manual state intended by one Pi session.

**Dwell** — The minimum time an applied state remains before another state is activated, giving Ghostty time to reload and making transitions visible.

**Focus routing** — Herdr-driven ownership logic that decides whether a Pi pane’s remembered state or `off` should become globally active.

**Forced state** — A compile-time shader constant selecting exactly one lifecycle expression instead of decoding a state from cursor color.

**Ghost state** — One of `idle`, `thinking`, `working`, `done`, `error`, or the visibility state `off`.

**Pane state** — The desired state persisted for one Pi pane inside one Herdr session.

**Projection** — The transformation of Pi’s internal lifecycle into ambient terminal visuals. The ghost reflects activity; it does not control the activity.

**Render plane** — The selected shader executing inside Ghostty against terminal pixels and uniforms.

**Runtime fragment** — The small Ghostty configuration file containing zero or one `custom-shader` path. It is the stable handoff between package code and Ghostty.

**Semantic state** — A user-meaningful phase such as thinking or working, distinct from raw events such as tool start.

**Variant** — A generated shader program with one forced-state value. Variants are alternatives selected by path, not shaders chained together.

**Visibility gate** — A condition that hides rendering without changing semantic intent: non-Pi pane focus at the controller layer or unfocused Ghostty at the shader layer.

Follow [[ai-artifacts/docs/semantic-map|the semantic map]] for relationships among these terms and [[ai-artifacts/docs/index|the documentation map]] for the rest of the knowledge base.
