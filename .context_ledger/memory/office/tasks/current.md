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

- **Session:** 2026-11-26 — Mateo (S023, re-opened) / claude-opus-4-8
- **Task:** stale Working rows accumulate across checkouts; future agents presume them live. Fix structurally (core 2.5.0).
  - root cause: `ledger-guard stale_rows()` keys off the LOCAL heartbeat file → blind to rows checked in on other checkouts (exactly the ones that go stale). Peer-row rule then freezes them forever.
  - fix: committed cross-checkout signal = last `Ledger-Session:` trailer date; sanctioned `sweep` command (evidence, not guess); surface in gate; refine peer-row rule.
  - evidence: Elias S019 last commit 2026-10-20 (37d), no Session-19 entry → definitively abandoned; sweep it.
- **Status:** in-progress
- **Open (prior, still parked):** triage 42 harvested flaws; ps1 Windows verification pass; codename-direction ruling; office is 20/20 FULL (ledger-history close due).
