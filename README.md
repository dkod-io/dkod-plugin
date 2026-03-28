# dkod Plugin for Claude Code

Parallel agent execution on shared codebases with AST-level semantic merging.

Multiple agents edit the same files and functions simultaneously — dkod handles conflicts automatically.

## Install

```
/plugin marketplace add dkod-io/dkod-plugin
/plugin install dkod@dkod
```

## What's included

| Component | Description |
|-----------|-------------|
| **MCP Server** | HTTP transport to dkod cloud — 12 tools including `dk_connect`, `dk_context`, `dk_file_read`, `dk_file_write`, `dk_file_list`, `dk_submit`, `dk_verify`, `dk_approve`, `dk_merge`, `dk_push`, `dk_status`, `dk_watch` |
| **Skill** | Teaches agents to parallelize work — decompose by symbol, launch concurrent sub-agents, handle conflicts |
| **Agent** | `parallel-executor` — orchestrates multi-agent workflows with automatic landing |
| **Commands** | `/dkod:status`, `/dkod:push`, `/dkod:watch`, `/dkod:land` |
| **Hooks** | `SubagentStart` — reminds sub-agents to create their own dkod sessions |

## How it works

1. **Connect** — each agent gets an isolated session (`dk_connect`)
2. **Work** — agents read, write, and query code independently (`dk_context`, `dk_file_read`, `dk_file_write`)
3. **Submit** — agents submit their changes (`dk_submit`)
4. **Verify** — automated checks run (`dk_verify`)
5. **Approve** — approve changesets if no conflicts (`dk_approve`)
6. **Merge** — AST-level merge combines changes (`dk_merge`)
7. **Push** — create a GitHub PR with all changes (`dk_push`)

Or use `/dkod:land` to auto-approve, merge, and push everything in one step.

Two agents editing different functions in the same file? Auto-merged. Same import added twice? Deduplicated. True semantic conflict? Surfaced with full context — never silently overwritten.

## Real-time conflict awareness

When multiple agents work on the same file, each agent receives real-time notifications about other agents' changes via `dk_watch`. Warnings are tagged `[AFFECTS YOUR WORK]` when another agent modifies symbols you're also editing.

## Authentication

On first use, a browser window opens for GitHub OAuth. After that, dkod tools are available in all sessions.

## Links

- [dkod.io](https://dkod.io) — Platform
- [Documentation](https://dkod.io/docs) — Full docs
- [Quickstart](https://dkod.io/docs/getting-started/quickstart) — Get started in 2 minutes
- [dkod Engine](https://github.com/dkod-io/dkod-engine) — Open source engine (MIT)
