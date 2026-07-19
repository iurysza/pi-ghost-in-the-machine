# Operations and Verification

Runtime truth lives under `~/.local/state/ghost-in-the-machine/`. Diagnose from intent toward pixels:

```mermaid
flowchart TD
    A[Command or lifecycle event] --> B{Desired pane state correct?}
    B -->|no| Pi[Inspect Pi mapping or enablement]
    B -->|yes| C{Focused pane owns it?}
    C -->|no| Herdr[Inspect Herdr identity and focus]
    C -->|yes| D{Fragment points to expected variant?}
    D -->|no| Controller[Inspect controller state selection]
    D -->|yes| E{Ghostty reloaded changed path?}
    E -->|no| Signal[Inspect SIGUSR2 and process]
    E -->|yes| Shader[Inspect shader compile or geometry]
```

The stable runtime fragment matters more than `active.state`; it is Ghostty’s actual input. A manual `/ghost-*` command separates lifecycle mapping from render failures.

Before shipping:

```sh
npm run generate
npm run check
npm test
npm pack --dry-run
```

Then verify thinking, working, error, and done visually; focus a non-Pi Herdr pane and return; unfocus and refocus Ghostty. The tarball must contain the extension, controller, setup script, shaders, Herdr plugin, attribution, and this map.
