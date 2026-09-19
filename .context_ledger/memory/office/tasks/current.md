# Current Task (overwrite each session)

Holds exactly one task — the one being worked on right now. Set it at
session start (protocol Step 3), clear it at session end (Step 15). If
you find a stale in-progress entry here, a prior session died mid-task —
its roster row (if left behind) says who was here; check the session
entry and backlog before starting.

<!-- TEMPLATE — replace everything below this comment:
- **Session:** YYYY-MM-DD — <agent> / <model>
- **Task:** <what is being worked on right now>
- **Status:** in-progress | done | blocked (<blocker>)
-->

- **Session:** 2026-09-19 — Priya / claude-sonnet-5
- **Task:** fix the check-in-first regression: core 2.0.0/2.0.1's thinned AGENTS.md dropped the standalone "check in before anything else" directive that the pre-2.0.0 AGENTS.md carried as one of its Ten Binding Rules — restore it as the weak-agent floor without reverting the token savings
- **Status:** in-progress
