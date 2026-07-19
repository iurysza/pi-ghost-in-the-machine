# Sidebar watcher performance

Equal 15s idle windows at a 50ms interval against /Users/iurysouza/.config/herdr/herdr.sock. Initial transition-controller work is excluded by a 750ms warmup. Process launches for the legacy watcher are derived from observed Herdr CLI calls: one `herdr`, two `jq`, and one `sleep` per poll.

| Metric | Bash/CLI/JQ | Node/socket |
| --- | ---: | ---: |
| Polls/second | 12.60 | 10.13 |
| Persistent RSS | 7.18 MiB | 47.41 MiB |
| Max RSS | 7.20 MiB | 49.81 MiB |
| Mean %CPU | 1.60 | 0.44 |
| Watcher CPU time | 0.250s | 0.070s |
| Herdr CPU-time delta | 1.320s | 1.980s |
| Steady-state child launches | 756 | 0 |

Node watcher summary: `watcher=stop reason=signal polls=152 successful_polls=152 avg_latency_ms=92.378 max_latency_ms=118.012 polls_per_second=10.038`

## Interpretation

The Node watcher cut its own measured CPU time from 0.250s to 0.070s and removed 756 short-lived child launches during this 15-second sample. Stable RSS increased by about 40.23 MiB. That is the intended trade: memory stays allocated, while process churn and watcher CPU fall.

Do not claim a Herdr server CPU win from this sample. The whole-server CPU-time delta includes unrelated live Herdr work. Both implementations still ask Herdr to compute `pane.layout`; this refactor removes client-side process churn, not server-side polling cost. An upstream sidebar event remains the only way to remove that cost.

The configured interval is 50ms, but requests never overlap. Live server response latency determines the actual poll rate.
