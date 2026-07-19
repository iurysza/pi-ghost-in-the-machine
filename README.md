# pi-ghost-in-the-machine

A tiny ASCII ghost living in Ghostty. Its face follows Pi: thinking, working, done, error, or quietly idle.

## What is included

- Pi lifecycle extension
- Ghostty shaders for every state
- Reproducible shader variant generator
- Ghostty state controller and setup script
- Herdr focus plugin so non-Pi panes hide the ghost

The repository is self-contained; it does not require a separate shader checkout or shell wrapper.

## Requirements

- Pi 0.80.4+
- Ghostty 1.3+
- Bash, `pgrep`, and `jq`
- Herdr 0.7.4+ for focused-pane routing (optional)

## Install

```sh
pi install git:github.com/iurysza/pi-ghost-in-the-machine
~/.pi/agent/git/github.com/iurysza/pi-ghost-in-the-machine/scripts/setup.sh
```

The setup script:

1. adds the generated state fragment to `~/.config/ghostty/config`;
2. links the bundled Herdr plugin when Herdr is installed;
3. initializes the idle shader and asks Ghostty to reload.

Reload Pi after installation:

```text
/reload
```

### Manual Ghostty setup

If you do not want the setup script to edit your config, add these lines yourself:

```ini
config-file = ?/Users/you/.local/state/ghost-in-the-machine/ghostty-state.conf
custom-shader-animation = true
```

Then initialize a state:

```sh
~/.pi/agent/git/github.com/iurysza/pi-ghost-in-the-machine/scripts/ghost-state.sh apply idle
```

For Herdr focus routing:

```sh
herdr plugin link ~/.pi/agent/git/github.com/iurysza/pi-ghost-in-the-machine
```

## Lifecycle states

| Pi event | Ghost state |
| --- | --- |
| Session starts | `idle` |
| Input or agent starts | `thinking` |
| Bash, edit, or write tool starts | `working` |
| Other tools start | `thinking` |
| Tool fails | `error` |
| Agent settles | `done`, or `error` after a failed tool |
| Session shuts down | `off` |

States remain visible for at least two seconds so Ghostty has time to reload and compile the selected shader.

## Commands

| Command | Action |
| --- | --- |
| `/ghost-idle` | Show the idle state |
| `/ghost-thinking` | Show the thinking state |
| `/ghost-working` | Show the working state |
| `/ghost-done` | Show the done state |
| `/ghost-error` | Show the error state |
| `/ghost-off` | Hide until the next Pi event |
| `/ghost-on` | Enable and restore the desired state |
| `/ghost-disable` | Disable for the current Pi session |
| `/ghost-status` | Show extension and active shader state |

## How it works

Ghostty 1.3.1 does not watch shader file contents. The controller instead rewrites a small config fragment so `custom-shader` points to a different bundled variant, then sends Ghostty its supported external reload signal, `SIGUSR2`. Because the configured path changes, Ghostty rebuilds the shader pipeline.

Herdr does not forward the OSC cursor-color channel needed by the original shader integration. The bundled Herdr plugin tracks `pane.focused`, restores each Pi pane's last state, and removes the shader when a non-Pi pane is focused.

Runtime files live under:

```text
~/.local/state/ghost-in-the-machine/
```

## Experimental sidebar probe

Without modifying Herdr, the bundled probe polls the current pane layout and logs geometry transitions:

```sh
scripts/watch-sidebar.sh /tmp/ghost-sidebar-watch.log
```

It uses `~/.local/bin/herdr` when `herdr` is missing from `PATH`. With Herdr's default desktop layout, `area.x <= 4` is classified as collapsed and larger values as expanded. This is diagnostic only: hidden-sidebar mode can be ambiguous with Herdr's mobile layout.

## Development

```sh
npm install
npm run generate
npm run check
npm test
npm pack --dry-run
```

`shaders/ghost-in-the-machine.glsl` is the source shader. Commit the generated files in `shaders/variants/` after changing it.

## Source and credit

The original shader concept and implementation came from [isoden/claude-terminal-face](https://github.com/isoden/claude-terminal-face). This repository is a new standalone Pi package built from that shader, with lifecycle variants, Ghostty path switching, Herdr routing, packaging, and visual changes. See [NOTICE](NOTICE) and [LICENSE](LICENSE).
