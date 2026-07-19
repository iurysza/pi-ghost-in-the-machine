# Agent Map

This file is the repository entrypoint, not a rulebook. Start with [[README|the public overview]], then enter [[ai-artifacts/docs/index|the documentation map]] and follow only the links your task needs.

For conceptual orientation, [[ai-artifacts/docs/semantic-map|the semantic map]] explains what the ghost is, which concerns cut across the system, and how the project’s vocabulary fits together. Pair it with [[ai-artifacts/docs/glossary|the glossary]] when a term such as state, desired state, active state, variant, fragment, dwell, or focus routing is ambiguous.

For behavior changes, read [[ai-artifacts/docs/lifecycle-and-data-flow|lifecycle and data flow]] before touching event mappings, queue semantics, error persistence, or manual commands. For changes that cross Pi, Ghostty, Herdr, the filesystem, or process signals, continue into [[ai-artifacts/docs/integration-boundaries|integration boundaries]]. [[ai-artifacts/docs/architecture|Architecture]] explains the moving pieces and why state selection is split from rendering.

Shader and visual work begins with [[ai-artifacts/docs/visual-model|the visual model]]. It describes the face coordinate system, forced-state variants, animation families, placement guarantees, and the relationship between source shader and generated variants without forcing an agent to reverse-engineer the GLSL first.

Installation, packaging, runtime state, failure diagnosis, and proof of correctness live in [[ai-artifacts/docs/operations-and-verification|operations and verification]]. Use that note before changing setup behavior, package contents, runtime paths, Herdr linking, CI, or release checks.

Keep durable agent knowledge inside `ai-artifacts/docs/` and connect it through [[ai-artifacts/docs/index|the documentation map]]. Keep user-facing installation and commands in [[README]]. When behavior or architecture changes, update the nearest semantic note rather than growing this entrypoint into another manual.
