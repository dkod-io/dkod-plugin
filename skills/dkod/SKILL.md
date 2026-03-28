---
name: dkod
description: >
  Enables fearless parallel agent execution on the same codebase, files, and functions
  simultaneously using dkod's AST-level semantic merging and session isolation. Use this skill
  whenever you are orchestrating sub-agents, agent teams, or parallel tasks that touch shared code.
  dkod eliminates merge conflicts between agents working on the same files by understanding code
  structure, not text. Also use when you find yourself serializing independent tasks, blocking
  agents waiting for each other, or avoiding parallel work because of conflict fears. If dkod MCP
  tools (dk_connect, dk_context, dk_file_read, dk_file_write, dk_file_list, dk_submit, dk_verify, dk_merge, dk_push, dk_status) are available, this skill applies.
compatibility: >
  Requires dkod MCP server (claude mcp add --transport http dkod https://api.dkod.io/mcp)
  or dkod CLI (dk). Works with Claude Code, Cursor, Codex, Windsurf, Cline, and any
  skills-compatible agent.
---

# Parallel Agent Execution with dkod

## First: Check if dkod is available

Before doing anything else, check whether the dkod MCP tools are accessible in your current
environment. Look for these tools: `dk_connect`, `dk_context`, `dk_file_read`, `dk_file_write`,
`dk_file_list`, `dk_submit`, `dk_verify`, `dk_merge`, `dk_push`, `dk_status`.

**If the tools are available** — skip to "The paradigm shift" below and start parallelizing.

**If the tools are NOT available** — the dkod MCP server is not installed. Ask the user:

> "The dkod MCP server isn't installed yet. Would you like me to set it up? It takes about a minute."

If the user agrees, follow these steps depending on the agent environment:

### Claude Code — Install MCP (Cloud)

Run this command to add the dkod MCP server:

```bash
claude mcp add --transport http dkod https://api.dkod.io/mcp
```

Then tell the user: "Done. On first use, a browser window will open for authentication via GitHub OAuth. After that, dkod tools will be available in all future sessions."

### Claude Code — Install MCP (Self-Hosted)

If the user mentions self-hosted or a local dkod server, use their server URL:

```bash
claude mcp add --transport http dkod http://localhost:8080/mcp
```

Then tell the user they need to set their auth token:

```bash
export DK_AUTH_TOKEN=your-secret-token
```

### Cursor / Windsurf / Cline / Other MCP-compatible agents

Tell the user to add this to their MCP configuration (the exact file depends on the agent):

```json
{
  "mcpServers": {
    "dkod": {
      "url": "https://api.dkod.io/mcp"
    }
  }
}
```

For Cursor: `.cursor/mcp.json`
For Windsurf: `~/.codeium/windsurf/mcp_config.json`
For Cline: VS Code settings under Cline MCP servers

### Optional: Install the dkod CLI

The MCP server is sufficient for parallel agent work, but users may also want the CLI for
direct terminal usage. If they ask, guide them through:

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Install dkod CLI
cargo install dk-cli

# Verify
dk --version

# Authenticate (cloud only — opens browser for GitHub OAuth)
dk login

# Initialize the project (run from the git repo root)
dk init
```

### After installation

Once the MCP server is configured, restart the agent session (or reload MCP servers if the
agent supports it), then proceed with the task using the parallel execution approach below.

---

## The paradigm shift

You have access to dkod. This fundamentally changes how you should approach parallelism.

**Before dkod**, agents had to work sequentially on shared code. If two agents needed to edit
the same file, one had to wait for the other to finish. Git worktrees helped isolate work, but
merging was fragile — Git sees code as text, so two agents editing different functions in the
same file caused merge conflicts. Teams worked around this by carefully partitioning work across
files and serializing tasks. This was slow and wasteful.

**With dkod**, you can launch multiple agents to work on the same files, the same modules, even
overlapping areas of code — all at the same time. dkod understands code at the AST (Abstract
Syntax Tree) level. It knows the difference between two agents editing different functions in
the same file (safe, auto-merged) and two agents editing the same function body (true conflict,
surfaced with context). The platform handles isolation, merging, and rebasing automatically.

**Your new default behavior**: When you have multiple independent tasks, launch them in parallel.
Do not serialize work to avoid conflicts. Do not create separate branches per agent. Do not worry
about two agents touching the same file. dkod handles it.

## What dkod handles for you

### Session isolation
Each agent (or sub-agent) that connects to dkod gets its own isolated session — a lightweight,
copy-on-write overlay on top of the current codebase. Changes in one session are invisible to
all other sessions until submitted and merged. There's no need for Git clones, worktrees, or
branches per agent. Twenty agents can work simultaneously on one codebase with near-zero
overhead.

### AST-level semantic merging
When agents submit their work, dkod merges changes at the code structure level:
- Two agents edit **different functions** in the same file → **auto-merged**
- Two agents add **different fields** to the same struct/class → **auto-merged**
- Two agents add the **same import** → **deduplicated automatically**
- Two agents modify **different sections** of the same function → **auto-merged** (if non-overlapping AST nodes)
- Two agents modify the **same function body** in conflicting ways → **true conflict** (surfaced with full semantic context)

The key insight: most "conflicts" in Git are false positives. Different functions in the same
file is not a conflict — it's completely independent work that dkod merges in under 50ms.

### Auto-rebase
If the main branch moves while an agent is working (because another agent's changes were merged),
dkod auto-rebases compatible changes. The agent doesn't need to pull, rebase, or handle merge
conflicts manually. If there's an actual conflict, the agent gets a structured error with
semantic context explaining what conflicted and why.

### True conflict detection
dkod catches conflicts that Git misses entirely. If Agent A deletes a function and Agent B adds
a call to that function, Git won't flag it until tests fail at runtime. dkod catches it at merge
time because it understands the dependency graph — Agent B's change depends on a symbol that
Agent A removed.

## How to parallelize

### Decompose by symbol, not by file
When splitting work across agents, think in terms of **functions, classes, and modules** — not
files. Two agents can safely work on the same file as long as they're editing different symbols.

**Good decomposition:**
- Agent 1: "Add input validation to `createUser()` and `updateUser()`"
- Agent 2: "Add input validation to `deleteUser()` and `listUsers()`"
- Agent 3: "Write tests for user validation functions"

All three may touch `user-handler.ts` — that's fine. They're working on different symbols.

**Unnecessary serialization (avoid this):**
- Agent 1: "Work on user-handler.ts" → Agent 2 waits → Agent 3 waits
This wastes time. The agents aren't conflicting, and dkod will merge their work automatically.

### Launch sub-agents concurrently
When you identify independent tasks, launch all sub-agents at the same time. Each sub-agent
should:

1. **Connect** its own dkod session (via `dk_connect`)
2. **Query context** for the symbols it needs (via `dk_context`)
3. **Read and write** files through its session overlay (via `dk_file_read` / `dk_file_write`)
4. **Submit** its changeset when done (via `dk_submit`)
5. **Verify** the submission passes checks (via `dk_verify`)
6. **Merge** into the main codebase (via `dk_merge`)

Each agent works independently. No coordination needed between them. The platform handles
the rest.

### After all agents finish: Push to GitHub

Once all agents have merged their changes internally, the orchestrating agent calls `dk_push`
to create a clean feature branch and optional PR on GitHub:

```
All agents done → dk_push(mode: "pr", branch: "feat/xyz", title: "Add feature XYZ")
```

`dk_merge` is internal only — it lands changes into dkod's main branch. `dk_push` is what
sends those changes to GitHub as a feature branch + PR with one commit per agent's changeset.

### Handling hard conflicts

When `dk_merge` detects a true conflict (two agents modified the same function body), it returns
a **ConflictResolution** response instead of an error. The response includes:
- Which symbols conflicted and why
- Suggested action: `adapt` (reconnect and rewrite), `keep_mine`, or `keep_theirs`
- A dashboard URL for visual 3-way diff

**For sub-agents:** The agent should report the conflict to its parent via SendMessage. The parent
presents options to the user. Once the user decides, the parent sends the decision back.

**For the `adapt` action:** The agent reconnects (`dk_connect`), reads the updated base (which now
includes the other agent's merged changes), rewrites its changes to work alongside them, and
re-submits → re-verifies → re-merges.

### Don't fear overlapping work
If you're unsure whether two agents might touch the same code — launch them anyway. The worst
case is a true semantic conflict, which dkod will surface clearly with:
- Which symbols conflicted
- What each agent changed
- Suggested resolution

This is far better than the alternative: serializing work "just in case" and wasting time.

## What's safe and what conflicts

| Scenario | Result |
|----------|--------|
| Two agents modify different functions in the same file | **Auto-merge** |
| Two agents add different fields to the same struct/class | **Auto-merge** |
| Two agents add the same import statement | **Deduplicated** |
| Two agents modify different sections of the same function | **Auto-merge** |
| Two agents add the same parameter to a function | **Deduplicated** |
| Two agents modify the same function body in conflicting ways | **Conflict** (surfaced with context) |
| Agent A deletes a function that Agent B calls | **Conflict** (caught at merge time) |

The last row is important: dkod catches **more real conflicts** than Git because it understands
dependencies. Git won't flag a broken call site until tests fail.

## When to use this skill

Use parallel execution whenever you have:
- **Multiple independent tasks** — feature work, bug fixes, tests, refactoring that can proceed simultaneously
- **Batch operations** — applying the same change pattern across many modules (validation, logging, error handling)
- **Test + implementation split** — one agent writes code, another writes tests for it, simultaneously
- **Large refactors** — multiple agents each handle a subset of the migration

Do not serialize work unless tasks have strict sequential dependencies (Agent B literally cannot
start until Agent A's output exists). Even then, consider whether Agent B can start on other
parts of its work while waiting.

## Protocol reference

For the full dkod MCP workflow (connect, context, file operations, submit, verify, merge),
see [references/mcp-workflow.md](references/mcp-workflow.md).
