> [!IMPORTANT]
> **This repository is archived.** It is part of the pre-pivot dkod platform (parallel agent execution / AST merging) and is no longer developed.
>
> **dkod is now a git-native flight recorder for AI coding agents** — capture every agent session into your own git repo, with per-line `dkod blame` and intent-vs-output `dkod drift`. See **[dkod-io/dkod-cli](https://github.com/dkod-io/dkod-cli)**.

<p align="center">
  <a href="https://dkod.io">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/dkod-io/dkod-engine/main/.github/assets/banner-dark.svg">
      <img alt="dkod — Agent-native code platform" src="https://raw.githubusercontent.com/dkod-io/dkod-engine/main/.github/assets/banner-dark.svg" width="100%">
    </picture>
  </a>
</p>

<p align="center">
  <b>The official dkod plugin for Claude Code.</b>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-06b6d4?style=flat-square&labelColor=0f0f14"></a>
  <a href="https://code.claude.com/docs/en/plugins"><img alt="Claude Code Plugin" src="https://img.shields.io/badge/claude_code-plugin-06b6d4?style=flat-square&labelColor=0f0f14"></a>
  <a href="https://dkod.io"><img alt="Website" src="https://img.shields.io/badge/dkod.io-website-06b6d4?style=flat-square&labelColor=0f0f14"></a>
  <a href="https://discord.gg/q2xzuNDJ"><img alt="Discord" src="https://img.shields.io/badge/discord-community-06b6d4?style=flat-square&labelColor=0f0f14"></a>
  <a href="https://twitter.com/dkod_io"><img alt="Twitter" src="https://img.shields.io/badge/twitter-@dkod__io-06b6d4?style=flat-square&labelColor=0f0f14"></a>
</p>

<p align="center">
  <a href="https://dkod.io/docs/agents/claude-code">Documentation</a> &nbsp;&bull;&nbsp;
  <a href="https://dkod.io/docs/getting-started/quickstart">Quickstart</a> &nbsp;&bull;&nbsp;
  <a href="https://dkod.io/docs/guides/multi-agent-workflows">Multi-Agent Workflows</a> &nbsp;&bull;&nbsp;
  <a href="https://discord.gg/q2xzuNDJ">Discord</a>
</p>

<br>

## Install

Two commands. Everything you need in one plugin.

```
/plugin marketplace add dkod-io/dkod-plugin
/plugin install dkod@dkod
```

On first use, a browser window opens for GitHub OAuth. After that, dkod tools are available in all sessions.

> **Not using Claude Code?** Install the [dkod skill](https://github.com/dkod-io/skills) instead — works with Cursor, Windsurf, Cline, Codex, and any MCP-compatible agent.

<br>

## What's Included

| Component | What you get |
|-----------|-------------|
| **MCP Server** | 15 tools — `dk_connect`, `dk_context`, `dk_file_read`, `dk_file_write`, `dk_file_list`, `dk_submit`, `dk_verify`, `dk_review`, `dk_resolve`, `dk_approve`, `dk_merge`, `dk_push`, `dk_close`, `dk_status`, `dk_watch` |
| **Skill** | Teaches agents to decompose work by symbol, launch concurrent sub-agents, handle conflicts |
| **Agent** | `parallel-executor` — orchestrates multi-agent workflows with automatic landing |
| **Commands** | `/dkod:status` `/dkod:push` `/dkod:watch` `/dkod:land` |
| **Hooks** | `SubagentStart` — reminds sub-agents to create isolated dkod sessions |

<br>

## The Problem

AI agents serialize work to avoid conflicts. If two tasks touch the same file, one waits for the other. Git sees code as text — two edits to the same file means a merge conflict, even if the changes are completely independent.

**Your agents are fast. Git is holding them back.**

## The Fix

The dkod plugin teaches your agent a new default: **parallelize everything.**

<br>

<table>
<tr>
<td width="50%" valign="top">

### Not a Worktree

No clones, no forks, no branches per agent. dkod gives each agent an isolated **session overlay** — a lightweight, copy-on-write layer on top of a single shared codebase.

**One repo. Unlimited agents. Zero overhead.**

</td>
<td width="50%" valign="top">

### AST-Level Merging

dkod merges at the code structure level, not the text level. Two agents editing different functions in the same file? **Automatic merge in under 50ms.**

True conflicts are caught and surfaced with full semantic context.

</td>
</tr>
</table>

<br>

## What's Safe in Parallel

| Scenario | Result |
|----------|--------|
| Two agents edit different functions in the same file | **Auto-merge** |
| Two agents add different fields to the same struct | **Auto-merge** |
| Two agents add the same import | **Deduplicated** |
| Two agents modify different sections of a function | **Auto-merge** |
| Two agents modify the same function body | **Conflict** (surfaced with context) |
| Agent A deletes a function that Agent B calls | **Conflict** (caught at merge time) |

<br>

## How It Works

1. **Connect** — each agent gets an isolated session (`dk_connect`)
2. **Work** — agents read, write, and query code independently
3. **Submit** — agents submit their changes (`dk_submit`)
4. **Land** — approve, merge, and push in one step (`/dkod:land`)

Or do it manually: `dk_approve` → `dk_merge` → `dk_push`

Two agents editing different functions in the same file? Auto-merged. Same import added twice? Deduplicated. True semantic conflict? Surfaced with full context — never silently overwritten.

<br>

## Real-Time Conflict Awareness

Agents receive live notifications via `dk_watch` when other agents modify the same file. Warnings are tagged `[AFFECTS YOUR WORK]` with specific symbol names — so agents can adapt in real time instead of discovering conflicts at merge.

<br>

## Plugin Contents

```
dkod-plugin/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest (v1.1.0)
│   └── marketplace.json      # Marketplace catalog
├── .mcp.json                 # MCP server → api.dkod.io/mcp
├── skills/
│   └── dkod/
│       ├── SKILL.md          # Parallel execution behavioral guide
│       └── references/
│           └── mcp-workflow.md   # Full MCP protocol reference
├── agents/
│   └── parallel-executor.md  # Multi-agent orchestrator
├── commands/
│   ├── status.md             # /dkod:status
│   ├── push.md               # /dkod:push
│   ├── watch.md              # /dkod:watch
│   └── land.md               # /dkod:land (auto-pipeline)
└── hooks/
    └── hooks.json            # SubagentStart session reminder
```

<br>

## Community

<p align="center">
  <a href="https://discord.gg/q2xzuNDJ"><img src="https://img.shields.io/badge/Discord-Join_the_community-06b6d4?style=for-the-badge&labelColor=0f0f14" alt="Discord"></a>
  &nbsp;&nbsp;
  <a href="https://twitter.com/dkod_io"><img src="https://img.shields.io/badge/Twitter-Follow_@dkod__io-06b6d4?style=for-the-badge&labelColor=0f0f14" alt="Twitter"></a>
</p>

<br>

## License

MIT — free to use, fork, and build on.

<br>

<p align="center">
  <sub>Built for the age of agent-native development &bull; <a href="https://dkod.io">dkod.io</a></sub>
</p>
