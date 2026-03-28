---
description: Push merged dkod changes to GitHub as a branch or pull request
disable-model-invocation: true
---

Guide the user through pushing their merged dkod changes to GitHub.

1. Call `dk_status` to check for merged changesets
2. Ask the user for a branch name and whether they want a PR
3. Call `dk_push` with their choices:
   - `mode: "pr"` for a pull request (default)
   - `mode: "branch"` for just a branch
4. Display the resulting branch name and PR URL

If no changes have been merged yet, tell the user they need to complete the submit/verify/merge workflow first.

Use `$ARGUMENTS` as the branch name if provided (e.g., `/dkod:push feat/my-feature`).
