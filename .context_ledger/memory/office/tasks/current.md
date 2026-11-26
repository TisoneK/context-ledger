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

- **Session:** 2026-11-26 — Mateo (S023) / claude-opus-4-8
- **Task:** Supervisor directive — one theme (agent discipline / self-maintaining ledger) in six points:
  1. **Protocol-drift / no discipline** — agents follow protocol turn 1, then work from memory and skip it; corrections don't stick after a couple of turns. Root concern: the floor is advisory, not enforced per-turn. → promote to a rule/gate (the ledger's own doctrine).
  2. **New fleet projects** — bobly-tide, zett, gvi-agents not yet committed to `fleet.md` (found uncommitted in the working tree at check-in). Finish + commit.
  3. **Flaws across all repos** — audit open flaws for fixing across the fleet repos, not just this package. SCOPE: fleet = 11 repos, only this one is checked out locally → scope with supervisor before cloning all.
  4. **Retire fixed flaws** — flaws/log.md carries fixed-status entries (2.1.0, 2.3.2, 2.3.3) still in the active log; move them verbatim to flaws/archive.md.
  5. **Aggressive pruning** — ledger must not hoard data and burn tokens meant for building. Make prune/compaction aggressive (STATE digest size, floor length, append-only log growth).
  6. **Inconsistent codename convention** — agents use `S001` vs `OF01S01` interchangeably. Spec is ambiguous. Pick ONE canonical form, make it unambiguous, enforce it.
- **Status:** in-progress — checked in as S023; working points 2,4,5,6 here; 1 is a core/rule change (flag scope); 3 needs supervisor scope decision.
- **Live example of #1/#6 on the board:** Elias (S019) left `Working`, no task, no Session-19 entry — an abandoned row. Not dropped (peer-row rule); raised to supervisor.
