# Design: Sibling-agent cohorts and input comprehension

**Status:** proposed — awaiting supervisor ruling (§7). No code yet.
**Author:** Soren (S021) · 2026-10-30
**Origin:** a supervisor discussion that started from the **sibling-agent
pattern** (fan a multi-item task into parallel sessions, each its own
worktree, archive at the end) and worked back to what it exposes.
**Supersedes:** my own earlier same-session draft
`identity-enforcement-and-log-lifecycle.md`, which led with identity and
folded the other concerns under it — the wrong center (see §6).
**Evidence (in the tree, 2026-10-30):**
- Priya's S018 flaw (`flaws/log.md`) + what it already shipped: core
  2.1.0 per-turn rule **re-injection** hook, pre-commit/pre-push gates,
  sync-before-check-in, per-session heartbeat + `Ledger-Session` trailer
  (2.2.0). Still open there: a single rules digest (B-2026-10-04-2).
- The S016/S017 sync-collision flaw (two sessions, same codename off a
  stale board).
- This session's own evidence: three LocalMind sibling branches whose
  **ledger bookkeeping collided** and had to be union-merged by hand, then
  re-resolved after every sequential merge.
- Soren's S021 intake flaw (`flaws/log.md`): dense user messages collapse
  to their last point.

---

## 1. Where this came from — the capability

The pattern works and is worth naming: split a multi-item handoff into one
**sibling session per item**, each in its own worktree, let each run
kickoff + check-in itself, and archive them at the end. In LocalMind it
moved three unrelated backlogs at once with no shared-tree collisions. This
note is not a critique of that pattern — it is what the pattern *reveals*
the ledger does not yet model.

## 2. The ledger has no cohort primitive

The ledger models agents arriving **one at a time**: check in, claim a
codename by first-push-wins, work, clock out, the office fills slowly.
Sibling agents are a **cohort** — spawned together, each a clone, all
branching from and merging back into one ledger. The protocol treats
concurrency as an *accident to rebase around*, not the intended mode, so
every sibling run pays for it:

- **Codename races** — N siblings read the same board at once and grab the
  same number (the S016/S017 flaw, twice).
- **Guaranteed bookkeeping conflicts** — each sibling's exit checklist
  appends to the same `STATE.md` / `sessions.md` / logs, so the branches
  conflict on merge every time. This session resolved that by hand three
  times (union the append-only logs, regenerate `STATE.md`, re-resolve
  after each sequential merge). That recipe is deterministic — it should
  be a *defined protocol step*, not an improvisation.
- **No cohort attribution** — the N are really one dispatch from one
  contributor, but the ledger cannot say "these belong together."
- **Office fills N× faster** — the `office_size` cap assumes serial
  arrival.

**Proposed:** a first-class cohort/wave — spawned by a parent, codenames
**pre-allocated** so they cannot race, the shared-bookkeeping merge treated
as an *expected* step (union-logs + regenerate-STATE as a rule), and the
cohort reconciled/archived as a unit.

## 3. What is already built (do not reinvent)

Core 2.1–2.2 already answered "the protocol decays, agents must be forced"
for *protocol rules*: a prompt-time hook re-injects the critical rules +
roster + current task each turn, a pre-commit gate refuses a commit with no
fresh gate pass, push-check rejects mixed-surface / rewritten-append-only
commits, and a heartbeat + `Ledger-Session` trailer tag each commit. That
is **collection-at-the-point-of-action** for rules, and it is the right
shape. Two things it does *not* do (§4, §5).

## 4. The gap re-injection misses — input comprehension

The 2.1 hook pushes rules *into* context. Nothing pulls the user's points
*out* of a dense message. Attention rides recency, so a multi-point user
message collapses onto its last point or question (Soren S021 flaw;
demonstrated repeatedly in this very session). This is the supervisor's
explicit ask: **the ledger should enforce comprehension of dense input.**

**Proposed mechanism — an intake checklist.** When a user message carries
several distinct asks/observations, the agent enumerates them as an
"important points" list and must address or explicitly defer each before
closing the turn. **The list is written into the durable record
(`tasks/current.md`), not left in chat** — chat is the most volatile store
the agent has (it decays within a session and is gone on compaction or
resume), which is *why* the points are lost in the first place. Harvesting
them from chat into the ledger is the missing bridge: the ledger records
the agent's own session log but never the user's raw points, so the moment
chat compacts, the asks are gone. Fire it through the *same* prompt-time
hook that already re-injects rules, so it lands in the attended slot
instead of being one more line of decaying prose. This is the two-axis fix in one: it
re-**collects** the obligation at the point of action, and it forces
**attention** across all points, not the last.

## 5. Identity & security — the unbuilt hardening

The `Ledger-Session` trailer is, in Priya's own words, "only as honest as
the committing agent." It is unauthenticated: anyone with push access can
type any codename or author a commit as anyone. This session is the proof —
its commits are git-authored *Tisone Kironget* while *Soren (S021)* did the
work. For a single owner that is harmless; for multiple contributors it is
a real gap, and it is the same gap as cohort attribution and the
office-local `S001` ambiguity. **Proposed:** a structured, globally-unique
codename (`contributor·office·session`) bound to an **authenticated**
identity via **signed commits (SSH/GPG)**. Invasive (touches the trailer,
heartbeat, history-close) — worth it only once multiple contributors are
real (see §7).

## 6. Log lifecycle — already solved, just unenforced

`ledger-mem prune --apply` already archives resolved log entries verbatim
(never deletes). The only gap is that it is manual — it should run at exit,
which is the §3 pattern again. Not a new mechanism; an enforcement hook.

## 7. Decisions needed from the supervisor

- **Cohort.** Make the sibling cohort a first-class primitive (pre-allocated
  codenames + a defined bookkeeping-merge step)? This is the highest-value
  item and the one this session hit hardest.
- **Intake.** Adopt the input-comprehension checklist (§4) via the existing
  hook? (Lowest-cost, directly addresses the supervisor's ask.)
- **Identity/security.** Are multiple contributors real enough *now* to
  justify signed commits + structured codename (§5), or does the
  single-owner assumption hold a while longer?
- **Lifecycle.** OK to run `prune --apply` at exit automatically (§6)?
- **Per-writer files (§9, raised 2026-10-31).** Split the *per-agent*
  bookkeeping into per-writer files so a cohort can share one branch/tree
  with no contention — or keep the shared-file + union-merge model built in
  2.3.0, which suits the isolated-worktree mode?

## 8. Supervisor ruling

_(to be filled when the supervisor rules.)_

## 9. Follow-up — per-writer files vs shared-then-merge (supervisor, 2026-10-31)

Raised while the 2.3.0 cohort was shipping: *can't the siblings just not
share a contended file — e.g. `workflows/active.<agent>.md`, one file per
writer?* Yes, and it is the **stronger** form of the bookkeeping fix for the
state that is genuinely per-agent. It is the same principle the collaboration
events already use: one immutable file per writer under `events/`, so there
is simply **nothing to merge**. The two modes, made explicit:

- **Isolated worktree/branch per sibling** (what 2.3.0's `merge=union` +
  `ledger-state reconcile` serve). Branches only meet at merge; the
  append-only logs union there and STATE is regenerated. Safe against the
  stash/rebase-clobber hazard of a shared tree, at the cost of N worktrees.
- **Shared branch/tree** (what the supervisor is pointing at). Here per-writer
  files earn their place: each sibling writes only `tasks/current.<codename>.md`
  (and a per-session worklog of its own), never a file a peer also writes, so
  concurrent agents coexist in ONE checkout with **zero** ledger contention —
  no worktree needed for the bookkeeping's sake. A generated view aggregates
  the per-writer files (the way `STATE.md` already aggregates).

The split that falls out:

- **Per-agent state → per-writer files.** `tasks/current.md` (already a
  single-agent lock) becomes `tasks/current.<codename>.md`; a per-session
  worklog is already per-writer. No merge, either mode.
- **One shared chronological artifact → keep singular, union-append.**
  `agents/sessions.md` is one duty log in time order; union is exactly right.
- **The board → one view, ideally generated.** `roster.md` is *meant* to be a
  single at-a-glance table; splitting it defeats its purpose. The clean end
  state is per-agent status files with the board regenerated over them (like
  STATE), so even roster edits stop colliding.

Caveat that keeps worktrees honest: per-writer files fix the **ledger**
contention, not the **product** one. In a shared tree, two agents' product
edits and one agent's `git stash`/`rebase` can still swallow another's
uncommitted work (the S421 collision in LocalMind memory). So shared-tree
cohorts are safe only when product work is also cleanly partitioned
(disjoint files per sibling — which is exactly how this session's `rewind`
demo is carved: one module + one test per sibling). Worktree isolation stays
the default; per-writer files make shared-tree an option, not an obligation.

This is the next iteration after 2.3.0, not a patch to it: it changes file
layout (`tasks/current.md` → per-codename), `ledger-state` (aggregate the
per-writer files), and possibly the roster into a generated view — a MINOR,
maybe a MAJOR if the roster layout changes. Deferred to a supervisor ruling
(§7); 2.3.0's union path stands in the meantime and is what the live `rewind`
cohort exercises.
