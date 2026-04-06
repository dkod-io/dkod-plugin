---
description: Auto-approve, merge, and push all submitted changesets as a single PR — the full landing pipeline
disable-model-invocation: true
---

# Auto-Land Pipeline

Run the full landing pipeline for all submitted changesets in the current repo.

## Flow

1. Call `dk_status` to see all active sessions and their changesets
2. For each submitted changeset:
   a. Call `dk_approve` to approve it (if not already approved)
   b. Call `dk_merge` to merge it into the codebase
3. After all changesets are merged, call `dk_push` with mode="pr" to create a GitHub PR

## Review check (between submit and approve)

5. **Review** — `dk_review` — check code review score and findings
   - Score >= 3 and no "error" findings -> proceed to approve
   - Score < 3 or "error" findings -> report findings to user

## Conflict handling

- If `dk_merge` returns a conflict, STOP and report the conflict to the user with full details
- Do NOT force-merge or auto-resolve conflicts
- Show which agents' changes conflicted and on which symbols

## Usage

If $ARGUMENTS is provided, use it as the branch name and PR title:
- `/dkod:land feat/auth-upgrades` -> branch "feat/auth-upgrades", PR title "feat/auth-upgrades"

If no arguments, ask the user for a branch name and PR title.

## Important

- This command orchestrates dk_approve -> dk_merge -> dk_push in sequence
- Each step must succeed before proceeding to the next
- If any step fails, stop and report the error
- The resulting PR has one commit per agent's merged changeset
