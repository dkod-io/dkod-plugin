# dkod Plugin for Claude Code

Parallel agent execution on shared codebases with AST-level semantic merging.

Multiple agents edit the same files and functions simultaneously — dkod handles conflicts automatically.

## Install

```
/plugin install dkod
```

## What's included

| Component | Description |
|-----------|-------------|
| **MCP Server** | HTTP transport to dkod cloud — all dk_* tools |
| **Skill** | Teaches agents how to parallelize work with dkod |
| **Agent** | `parallel-executor` — orchestrates multi-agent workflows |
| **Commands** | `/dkod:status`, `/dkod:push`, `/dkod:watch` |
| **Hooks** | Auto-reminds sub-agents to create their own dkod sessions |

## How it works

1. **Connect** — each agent gets an isolated session (`dk_connect`)
2. **Work** — agents read, write, and query code independently (`dk_context`, `dk_file_read`, `dk_file_write`)
3. **Submit** — agents submit their changes (`dk_submit`)
4. **Verify** — automated checks run (`dk_verify`)
5. **Merge** — AST-level merge combines changes (`dk_merge`)
6. **Push** — create a GitHub PR with all changes (`dk_push`)

Two agents editing different functions in the same file? Auto-merged. Same import added twice? Deduplicated. True semantic conflict? Surfaced with full context.

## Authentication

On first use, a browser window opens for GitHub OAuth. After that, dkod tools are available in all sessions.

## Links

- [dkod.io](https://dkod.io) — Platform
- [Documentation](https://dkod.io/docs) — Full docs
- [dkod Engine](https://github.com/dkod-io/dkod-engine) — Open source engine (MIT)
