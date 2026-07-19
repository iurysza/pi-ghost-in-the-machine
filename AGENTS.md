# Agent Map

Start with [[README|the public contract]], then use [[ai-artifacts/docs/index|the engineering map]]. Do not load every note; follow the branch that matches the task.

[[ai-artifacts/docs/semantic-map|Semantic map]] explains the three kinds of state that cause most bugs: desired, pane, and active. [[ai-artifacts/docs/architecture|Architecture]] shows the control/render split and the Ghostty/Herdr constraints that shaped it. [[ai-artifacts/docs/lifecycle|Lifecycle]] covers timing, coalescing, and error persistence. [[ai-artifacts/docs/visual-model|Visual model]] covers shader generation and placement. [[ai-artifacts/docs/operations-and-verification|Operations]] is the setup, diagnosis, and release path.

Keep user instructions in [[README]]. Put only non-obvious, durable engineering knowledge under `ai-artifacts/docs/`, then link it from [[ai-artifacts/docs/index|the map]].
