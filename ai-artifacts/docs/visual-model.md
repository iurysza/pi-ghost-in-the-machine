# Visual Model

The ghost is an ambient status signal, not an overlay widget. It is rendered from signed-distance fields into a small pseudo-ASCII glyph grid and composited behind terminal content. Bright terminal pixels suppress the ghost, preserving text legibility; dark space reveals it.

One source shader defines the complete visual language. Generated variants differ only by a forced-state constant: idle, thinking, working, done, or error. This keeps geometry and animation fixes consistent across states. `off` is normally represented by removing the shader path rather than rendering a pass-through variant.

Expressions combine eyes, mouth, color, and decoration. Idle drifts through relaxed variants. Thinking uses yellow and a moving question mark. Working uses blue and effort particles. Done uses green and sparkles. Error uses red and a worried expression. Motion shared across states—breathing, drift, banking, blink, and gaze wandering—makes transitions feel like one creature rather than unrelated badges.

Ghostty’s fragment coordinates are treated as top-down in the tested environment. The face center sits at forty percent of viewport height from the top. Scale is proportional to viewport height, making the face stable across widths. Horizontal placement starts from the Herdr sidebar center, then clamps the full animated footprint so its leftmost point keeps a half-percent viewport gap. The footprint includes drift and decorations, not only the eyes and mouth.

The visual model has two visibility gates. The controller removes the shader when the focused Herdr pane is not Pi. The shader itself returns the unmodified terminal texture when Ghostty reports `iFocus == 0`. Neither gate changes the desired expression; visibility can disappear and return without losing pane state.

The source is derived from [isoden/claude-terminal-face](https://github.com/isoden/claude-terminal-face), as recorded in [[README#Source and credit|the README]], `NOTICE`, and `LICENSE`. New visual work should preserve attribution and regenerate every variant from the single source. Verification belongs to [[ai-artifacts/docs/operations-and-verification|operations and verification]].
