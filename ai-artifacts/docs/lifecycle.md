# Lifecycle

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> thinking: input or agent start
    done --> thinking: next input
    error --> thinking: next input
    thinking --> working: bash, edit, write
    thinking --> done: settled
    working --> done: settled
    thinking --> error: tool failure
    working --> error: tool failure
    error --> error: settled after failure
    idle --> off: shutdown or non-Pi focus
    done --> off: shutdown or non-Pi focus
    off --> idle: Pi pane restored
```

Raw events arrive faster than Ghostty compiles this shader. The extension keeps each applied state for two seconds and retains only the newest queued request. This shows progression without replaying every read/write alternation after the turn ends.

A tool failure marks the whole turn. Settlement stays `error`; a later success in the same turn does not erase it. `/ghost-off` is temporary. `/ghost-disable` suppresses automatic transitions for the session.

Focus transitions do not change desired or pane state. They only choose which remembered state becomes active. See [[ai-artifacts/docs/semantic-map|semantic map]].
