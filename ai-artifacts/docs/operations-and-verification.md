# Operations and Verification

Installation has two independent effects. Pi installs and loads the package extension. Ghostty must also include the stable runtime fragment, and Herdr may link the focus plugin. The bundled setup script performs the latter two integrations explicitly; package installation alone cannot safely edit terminal configuration.

Runtime state lives under `~/.local/state/ghost-in-the-machine/` unless `XDG_STATE_HOME` overrides it. The important evidence is the fragment’s selected shader path and the recorded active state. Pane files explain what hidden Pi panes intend. The package directory contains source and generated shaders but should contain no mutable runtime state.

When a visual transition fails, diagnose the pipeline in order. Confirm the Pi command exists and reports an intended state. Confirm the pane state changed when inside Herdr. Confirm the runtime fragment points at the expected bundled variant. Confirm Ghostty received or can receive `SIGUSR2`. Finally, separate shader compilation from state routing by selecting a manual state. This order avoids blaming GLSL for a missing focus owner or blaming Pi for an unchanged config path.

Shader changes require regeneration because Ghostty loads committed forced-state variants, not the source shader. Regeneration should change every lifecycle variant consistently. A live verification should force at least thinking, working, error, and done; switch to a non-Pi Herdr pane; return to the Pi pane; and unfocus/refocus Ghostty.

Package verification follows the same contract as other standalone Pi extensions:

```sh
npm run generate
npm run check
npm test
npm pack --dry-run
```

`check` covers strict TypeScript and shell syntax. Tests prove manifest completeness, command registration, expected forced-state constants, stable state storage, and the reload signal. The dry-run package listing proves that extension, controller, shaders, setup, Herdr plugin, README, license, and notice ship together.

CI repeats checks, tests, and package inspection on pushes and pull requests. Before release, also inspect the generated diff, run Ghostty config validation in a real installation, and verify one complete lifecycle visually. The semantic expectations for that lifecycle live in [[ai-artifacts/docs/lifecycle-and-data-flow|lifecycle and data flow]].
