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

- **Session:** (idle)
- **Task:** none in progress — S023 (Mateo) closed out 2026-11-26 after shipping core 2.4.0 (enforced codenames + exit auto-prune + LLM-terse rule), fleet +3, root flaws 64KB→12KB, and a fleet harvest (42 open flaws → inbox, triage pending).
- **Status:** done
- **Open for next session:** triage the 42 harvested flaws; ps1 Windows verification pass; codename-direction ruling (S<NNN> vs OF<NN>SS<NN>); Elias (S019) stale Working row.
