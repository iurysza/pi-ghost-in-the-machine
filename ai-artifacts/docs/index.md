# Ghost in the Machine — Documentation Map

[[AGENTS|The agent map]] is the first disclosure layer. This page is the knowledge-base index: it connects domain meaning, runtime mechanics, integrations, visual behavior, and operations without turning any single document into a monolith.

Begin with [[ai-artifacts/docs/semantic-map|the semantic map]] to understand the project as a system of meaning rather than a pile of files. It introduces the ghost as a projection of Pi lifecycle state, separates state ownership from rendering, and names the concerns that recur across the extension, controller, shader, and focus integration. Keep [[ai-artifacts/docs/glossary|the glossary]] nearby; its terms are the shared language used by every other note.

Once the domain is clear, [[ai-artifacts/docs/architecture|architecture]] describes the moving pieces and their boundaries. [[ai-artifacts/docs/lifecycle-and-data-flow|Lifecycle and data flow]] follows concrete transitions from Pi events through dwell/coalescing, pane state, Ghostty configuration, shader compilation, and final rendering. Read both before changing responsibility or timing.

External systems are deliberately treated as boundaries rather than implementation details. [[ai-artifacts/docs/integration-boundaries|Integration boundaries]] explains what Pi, Ghostty, Herdr, the filesystem, and Unix signals each guarantee—and what they do not. This is the place to start when behavior works in one terminal context but disappears in another.

The face itself has a separate conceptual model. [[ai-artifacts/docs/visual-model|The visual model]] explains forced-state variants, coordinate conventions, scale and placement, animation families, focus visibility, and the provenance of the shader design. Read it before tuning geometry, colors, glyph density, expressions, or decorations.

Finally, [[ai-artifacts/docs/operations-and-verification|operations and verification]] joins installation, package shape, runtime storage, setup, diagnostics, generated assets, and release evidence. It is the shortest route for setup failures and the last stop before shipping.

[[README|The README]] remains the public contract: what users install, run, and expect. These notes are the agent-facing context behind that contract. When a change alters meaning, flow, integration assumptions, or proof, update the corresponding note and reconnect any new knowledge here.
