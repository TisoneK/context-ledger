# Parking Lot (deferred knowledge — not a queue)

The backlog is a work queue you act on; this file is the knowledge base
you **don't** act on yet. Research findings, open design questions,
advisory "should we…?" items, deferred work, and someday ideas live here
so the backlog stays a queue an agent can actually work from. Nothing
here is urgent, nothing here is capped, and nothing here blocks a gate.
The record of a finding is its own row plus the commit / session entry
that produced it; git history keeps every row, so promoting or dropping
one loses nothing.

**One rule keeps the two files honest: a parking-lot row is not a task.**
If an item becomes actionable — it now has a clear next step and someone
to take it — **promote** it: cut the row here, add an actionable row to
`backlog.md` (a fresh `B-` ID, one line, pointing back at this row's `P-`
ID if the context matters), and leave it here only as a one-line
"→ promoted to B-… " stub if you want the breadcrumb. An item that turns
out to be wrong or moot is just deleted — history remembers it.

Every row gets a stable **ID** — `P-<added YYYY-MM-DD>-<n>`, n = that
date's next sequence in the file — and a **Summary** cell with enough
context that a future session can pick it up cold. Keep status
qualifiers in the text ("advisory", "needs a decision", "blocked on X",
"deferred by owner"). There is **no cap** here and **no priority** —
items are grouped by *kind*, because the whole point is that these are
not competing for the top of a queue.

This file belongs to the **current office**. When the office closes, the
parking lot is **not** re-seeded wholesale: the closing session promotes
what is now actionable into the new backlog and records the rest in the
permanent record (`history/office-<NNN>.md`, "Open threads"). A cold
idea earns its way into the next office by becoming work, not by being
copied.

Full spec: `.context_ledger/core/schemas/ledger-schema.md` →
"The parking lot".

## Findings

What we learned that isn't work yet — observations, measurements, root
causes, "the current design does X because Y".

| ID | Summary |
|----|---------|
| P-2026-09-19-1 | `ledger-mem lint --tree` skips `.context_ledger/` but has no exclusion for this repo's own root-level `core/` (the package source, self-hosted) or its top-level meta-docs (`universal-kickoff.md`, `MIGRATION.md`, `QUICKSTART.md`, `README.md`, `designs/*.md`, `flaws/README.md`, `tests/run-tests.sh`) — all of which necessarily cite `.context_ledger/` paths because they *are* the protocol's own documentation, not product code the lint rule is meant to police. Found while running gates during Session 15's core 2.0.3 work: `lint --tree` currently reports 845 LEAK lines against this repo, up from the 87 Amari/S010 already logged (2026-09-14, still open) for just `README.md`/`AGENTS.md`. Same root cause, much bigger blast radius than previously measured — Amari's suggested fix (a `lint-exclude|<path>` line in `gates.conf`, or auto-exempting self-documenting product repos) would cover this too. Advisory only — `lint --tree` isn't in the pre-commit gate, so it's loud but non-blocking. |
| P-2026-09-23-1 | The ps1 ports' user-visible text still diverges from the sh ports' in places, independently of the encoding bug 2.0.4 fixed. Measured by running each port's `help` + report commands on one scratch office and diffing: 272 diff-lines raw, 131 after normalizing every em-dash to a hyphen — so roughly half punctuation (`ledger-mem`'s usage block, the gates office-full notice, several `ledger-history` lines) and half genuinely different text (the ps1 ports carry shorter `Commands:`-style usage blocks where the sh ports have long annotated ones). `ledger-state` no longer diverges (2.0.4 requires byte-identical STATE.md and a test pins it). Not fixed: whether "behaviorally identical" means byte-identical *help text* is a package decision, and the sh usage blocks look deliberately richer. Evidence: the diff was produced with a scratch-project harness over all seven port pairs (`sh` vs `pwsh -File …ps1`, both emitting to the same directory). |

## Open questions

Advisory questions, decisions still up for grabs, "should we…?" — a
question is not a task until it has an owner and a next step (then it
becomes a backlog row or an ADR in `plans/decisions.md`).

| ID | Summary |
|----|---------|
| P-2026-09-23-2 | A consumer project reported `ledger-sync verify` diagnosing a **CRLF-only working-tree difference** as tampering ("core/ does not match its manifest … run rollback"). Not reproducible on 2.0.4 in this session: `verify_tree` CR-strips each file before hashing in both editions (its own comment says this is deliberate, for LF/CRLF copies made outside git), and a scratch core with *every* text file converted to CRLF verifies clean under `sh`, `pwsh` 7 and 5.1 (rc 0). Either the report described an older core, a mixed EOL state, or something else misattributed to EOL. Needs the consumer's exact case (which file, which port, manifest state) before it becomes work. |
| P-2026-09-23-3 | This repo's `gates.conf` has **no project commands**, so `pre-commit` runs only the universal staged-diff check and `integration`/`exit` run no project commands — the package test suite (`sh tests/run-tests.sh`, 63 tests) is enforced by README discipline alone, not by any gate. Should `pre-commit`/`exit` run it? Tradeoff: the suite takes minutes (scratch projects, engine invocations) on every commit, which may be the reason it was left out; a middle option is `exit`-only, or a fast subset at pre-commit. `mode=hybrid` currently just prints a NOTICE each commit, so the gap is visible but easy to ignore. |

## Deferred work

Real tasks, consciously parked — not now, but keepable. This is where a
backlog row goes when the cap forces a prune and the item still matters:
out of the queue, not into the void.

| ID | Summary |
|----|---------|

## Someday

Loose ideas with no owner and no hook yet. The lowest-pressure shelf.

| ID | Summary |
|----|---------|
| P-2026-09-18-1 | An atomic `ledger-checkin` script (read roster+sessions.md, compute next codename, append row, commit, push, print confirmation) to replace the multi-paragraph check-in reasoning a session currently has to do by hand. Considered and deliberately deferred during the core 2.0.0 token-optimization pass (larger and riskier than the rest of that work — concurrency/push semantics need real design, not a quick add). Discussed with the supervisor; not built. |

<!-- TEMPLATE — add one row to the matching section:
| P-<YYYY-MM-DD>-<n> | <enough context that a future session can pick
      this up cold — status qualifiers in the text; promote to the
      backlog when it becomes actionable> |
-->
