# dkod MCP Workflow Reference

Complete reference for the dkod MCP protocol. Each agent session follows this flow:
connect → context → read/write → submit → verify → merge → push.

## Table of Contents

1. [Connect — Start a session](#connect)
2. [Context — Query code intelligence](#context)
3. [File Operations — Read and write code](#file-operations)
4. [Submit — Send a changeset](#submit)
5. [Verify — Run verification gates](#verify)
6. [Merge — Land the changeset](#merge)
7. [Push — Send to GitHub](#push)
8. [Status — Inspect the session](#status)
9. [Multi-Agent Example](#multi-agent-example)

---

## Connect

**Tool:** `dk_connect`

Establishes an agent session with an isolated workspace overlay on the target codebase.

**When to call:** At the start of every agent or sub-agent's work. Each agent must have its own
session — never share sessions between agents.

**What happens:**
- Creates a copy-on-write overlay on the current codebase snapshot
- Returns a session ID used for all subsequent operations
- Near-instant (~50ms) regardless of repository size
- No disk cost for unmodified files — only changed files consume space

**Key behaviors:**
- The session sees a consistent snapshot of the codebase at connection time
- Other agents' changes are invisible until they merge into main
- If main moves (another agent merges), your session auto-rebases on submit

---

## Context

**Tool:** `dk_context`

Queries the semantic code graph for code intelligence — symbols, call graphs, dependencies,
type information.

**When to call:** Before making changes, to understand the code you're about to modify. Also
useful for finding all callers of a function, understanding type hierarchies, or mapping
dependencies.

**Query types:**
- **Symbol lookup** — find a function, class, type, or variable by name
- **Call graph** — who calls this function? What does this function call?
- **Dependency graph** — what external packages does this module use?
- **Semantic search** — natural language queries like "authentication middleware"

**Why this matters for parallel work:** Context queries are read-only and session-isolated.
Multiple agents can query context simultaneously without interfering with each other. Use
context to understand the code before you write — this reduces the chance of true semantic
conflicts because agents make informed changes.

---

## File Operations

**Tools:** `dk_file_read`, `dk_file_write`, `dk_file_list`

Read and write files through the session overlay.

**`dk_file_read`** — Reads a file. Returns the overlay version if the agent has modified it,
otherwise falls through to the shared base. Zero cost for unmodified files.

**`dk_file_write`** — Writes a file into the session overlay only. The change is invisible to
all other sessions and to the main branch until submitted and merged.

**`dk_file_list`** — Lists files in the workspace, including any new files created in the overlay.

**Key behaviors:**
- Writes are local to the session — no other agent sees them
- Multiple agents can write to the same file simultaneously in their own overlays
- The merge engine reconciles overlapping writes at submit time using AST-level analysis

---

## Submit

**Tool:** `dk_submit`

Sends the session's changeset (all file modifications) for verification and merge.

**When to call:** When the agent has completed its task and is ready to land the changes.

**What happens:**
1. The platform diffs the overlay against the base snapshot
2. If the base has moved (another agent merged changes), auto-rebase is attempted
3. If auto-rebase succeeds (no true conflicts), the changeset proceeds to verification
4. If there's a true semantic conflict, a structured error is returned with details

**What a changeset contains:**
- All modified files (the diff from base to overlay)
- Structured rationale (what was changed and why)
- Semantic metadata (which symbols were modified, added, or removed)

---

## Verify

**Tool:** `dk_verify`

Runs the automated verification pipeline on the submitted changeset.

**When to call:** After submit, to ensure the changes pass all checks before merging.

**What it runs:**
- Type checking
- Linting
- Affected tests (only tests impacted by the changed symbols, not the full suite)
- Custom verification rules defined by the team

**On failure:** Returns structured results showing exactly what failed, which files/symbols
are involved, and suggested fixes. The agent can fix the issues, re-submit, and re-verify.

---

## Merge

**Tool:** `dk_merge`

Merges the verified changeset into the main codebase.

**When to call:** After verification passes successfully.

**What happens:**
- The changeset is merged using AST-level semantic merging
- Both the Git layer and the semantic code graph are updated atomically
- Other agents' sessions automatically see the new state on their next rebase
- Merge completes in under 50ms for typical changesets

**After merge:** The session can continue working on additional changes, or disconnect.
Other agents' auto-rebase will pick up these changes transparently.

**On conflict:** If the merge detects a true semantic conflict, `dk_merge` returns a
`ConflictResolution` response (not an error) containing:
- `conflicts` — list of conflicting symbols with file paths, your agent, their agent, descriptions
- `suggested_action` — typically `adapt` (reconnect and rewrite on updated base)
- `available_actions` — `adapt`, `keep_mine`, `keep_theirs`

The agent should report the conflict to its parent or the user. Resolution options:
- **adapt** (recommended): reconnect via `dk_connect`, read the updated code, rewrite changes, re-submit → re-verify → re-merge
- **keep_mine**: force-merge, discarding the other agent's conflicting changes
- **keep_theirs**: discard this agent's changeset

Conflicts can also be resolved via the dashboard's visual 3-way diff at the URL returned in the response.

---

## Push

**Tool:** `dk_push`

Pushes all merged changesets to GitHub as a feature branch, with an optional pull request.

**When to call:** After all agents have completed and merged their work. This is typically
called by the orchestrating agent (parent), not by individual sub-agents.

**Parameters:**
- `mode` — `"branch"` (push only) or `"pr"` (push + create PR)
- `branch_name` — target branch name (e.g., `feat/add-validation`)
- `pr_title` — PR title (required when mode is `pr`)
- `pr_body` — PR description (optional)

**What happens:**
- Collects all merged changesets from the session
- Creates one commit per changeset on the feature branch
- Optionally opens a PR to main via the GitHub API
- Returns: branch name, PR URL (if mode=pr), commit hash

**Key insight:** `dk_merge` is internal to dkod. `dk_push` is what sends changes to GitHub.
Separating these gives the orchestrating agent full control over when and how code ships.

---

## Status

**Tool:** `dk_status`

Inspects the current session state at any time.

**Returns:**
- Session ID and connection status
- Base codebase version
- List of modified files in the overlay
- Whether the base has moved since connection (pending rebase)
- Any outstanding conflicts or verification failures

---

## Multi-Agent Example

Here's how three agents work in parallel on the same codebase:

```
Agent A (add validation)          Agent B (add tests)           Agent C (update docs)
│                                 │                              │
├─ dk_connect                     ├─ dk_connect                  ├─ dk_connect
│  → session-a                    │  → session-b                 │  → session-c
│                                 │                              │
├─ dk_context                     ├─ dk_context                  ├─ dk_context
│  "user API endpoints"           │  "user API test coverage"    │  "user API documentation"
│                                 │                              │
├─ dk_file_write                  ├─ dk_file_write               ├─ dk_file_write
│  user-handler.ts                │  user-handler.test.ts        │  docs/user-api.md
│  (adds validation to            │  (adds test cases)           │  (updates API docs)
│   createUser, updateUser)       │                              │
│                                 │                              │
├─ dk_submit                      ├─ dk_submit                   ├─ dk_submit
├─ dk_verify ✓                    ├─ dk_verify ✓                 ├─ dk_verify ✓
├─ dk_merge ✓                     ├─ dk_merge ✓                  ├─ dk_merge ✓
│                                 │                              │
│  All three merge automatically — different symbols, no conflicts.
```

Even if Agent A and Agent B both read and write `user-handler.ts`, their changes target
different symbols (validation logic vs. test helpers) and merge cleanly.

After all three agents complete, the orchestrator pushes to GitHub:

```
Orchestrator
│
├─ dk_push(mode: "pr", branch: "feat/user-validation", title: "Add user validation")
│  → PR created with 3 commits (one per agent)
```
