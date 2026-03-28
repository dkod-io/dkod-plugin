---
description: Show real-time events from other agents working on the same codebase
disable-model-invocation: true
---

Call `dk_watch` to show buffered events from other agents working on the same codebase. Display:
- Which agents are active and what they're working on
- File modifications by other agents
- Conflict warnings if another agent is modifying the same symbols
- Merge events from other sessions

If no session is active, tell the user to connect first with `dk_connect`.
