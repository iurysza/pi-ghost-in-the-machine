# Integration Boundaries

**Pi** supplies lifecycle callbacks, commands, notifications, and subprocess execution. The package treats event ordering as bursty: input, agent start, tool start, tool end, and settlement may occur within one shader compile window. Pi owns session-local enablement and desired state; it does not own global terminal focus.

**Ghostty** supplies custom shaders and uniforms such as resolution, cursor data, time, and focus. Its reload contract is configuration-driven. The reliable state channel is a changed `custom-shader` path followed by `SIGUSR2`, not mutation of a watched shader file. Multiple shader entries compose sequentially, so state variants must be mutually selected rather than simultaneously configured. `iFocus` gates application-level visibility but cannot identify Herdr’s focused child pane.

**Herdr** supplies pane identity, agent identity, focus events, and the environment attached to each Pi pane. Its virtual terminal does not forward the OSC cursor-color behavior used by the source project, which is why this package routes state outside the child terminal. Herdr focus is global ownership information; the Pi extension’s local lifecycle cannot replace it.

**The filesystem** carries only small, non-secret runtime facts: the active state, one remembered state per pane, and the Ghostty fragment. Runtime state belongs under the user state directory, not inside the Git package. Shader variants belong in the package because the fragment must point at immutable, inspectable render programs.

**Unix process signaling** requests Ghostty reload with `SIGUSR2`. The signal carries no state; it only tells Ghostty to reread configuration. State must be committed to the fragment before signaling. Missing Ghostty processes are not fatal because the desired fragment remains available for a later launch.

**Package installation** may place the repository under different roots. Extension-to-controller and controller-to-shader paths are therefore package-relative. The one stable external path is the state fragment included by Ghostty.

Changes that blur these boundaries usually create fragile behavior: terminal escape sequences disappear inside multiplexers, mutable shader paths fail to trigger pipeline rebuilds, package-local runtime files are lost during updates, and focus guesses leak one pane’s state into another. Read [[ai-artifacts/docs/architecture|architecture]] before moving responsibility across a boundary.
