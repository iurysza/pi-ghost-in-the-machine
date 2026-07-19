# Semantic Map

Ghost in the Machine turns an invisible process lifecycle into a peripheral visual companion. Pi owns the work lifecycle; the package interprets that lifecycle as a small state vocabulary; Ghostty renders the selected state; Herdr decides whether the state belongs on the currently visible pane. The face is therefore not a process monitor or terminal theme. It is a **projection** of agent activity into ambient terminal feedback.

The central domain object is the **ghost state**. `idle`, `thinking`, `working`, `done`, and `error` describe user-meaningful phases rather than low-level events. `off` is different: it is absence of rendering, used when no eligible Pi surface owns the visible terminal. A manual command may change state directly, while automatic state comes from lifecycle interpretation. Both paths converge before rendering.

Three notions of state coexist. **Desired state** is what the Pi session most recently intends. **Pane state** is the desired state remembered for a particular Herdr pane. **Active state** is the shader path currently loaded by Ghostty. Keeping them distinct explains apparent races: a pane can desire `working` while a non-Pi pane makes the active state `off`, then recover `working` when focus returns.

Several concerns cut across the whole system. **Timing** prevents rapid lifecycle events from collapsing into an invisible compile storm. **Ownership** ensures one focused Pi pane controls the global Ghostty shader. **Identity** ties remembered state to a Herdr session and pane. **Visibility** combines pane eligibility with Ghostty application focus. **Reproducibility** keeps generated variants derived from one shader source. **Packaging** makes every runtime dependency discoverable from one repository.

The system has two planes. The **control plane** interprets events, remembers state, selects a variant path, and requests reload. The **render plane** is pure shader execution: it receives terminal pixels and Ghostty uniforms, then draws the current expression. This separation is load-bearing. The shader does not know Pi or Herdr, and Pi does not draw pixels.

Read [[ai-artifacts/docs/architecture|architecture]] for component responsibilities, [[ai-artifacts/docs/lifecycle-and-data-flow|lifecycle and data flow]] for transitions, and [[ai-artifacts/docs/glossary|the glossary]] for precise terms.
