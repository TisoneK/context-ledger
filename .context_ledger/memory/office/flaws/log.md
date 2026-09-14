# Flaws Log (append-only — flows to the protocol package)

Friction caused by the `.context_ledger/` system or the protocol itself. See
`README.md` in this directory for the split between `flaws/` and
`inefficiencies/`.

Append-only, but compactable — the log never grows without bound:

- **Resolved entries move verbatim** to cold storage: once an entry is
  explicitly marked `RESOLVED` / `superseded` / fixed, cut it unchanged
  into `archive.md` in this directory so startup reads only the live
  entries. Age alone never makes an entry eligible — an unresolved flaw
  stays here as a live trap.
- **Repeats roll up:** when 3+ entries describe the same recurring
  protocol trap, append ONE consolidated `Recurring` entry — the pattern,
  how many times, the current workaround — and move the individual
  entries verbatim into `archive.md`. The live log keeps the pattern, not
  the repeats.

`ledger-mem prune` reports log sizes, archive-eligible entries (`--list`
names them), and roll-up candidates.

<!-- TEMPLATE — copy below the last entry:
---
## YYYY-MM-DD — <agent> / <model> (Session N)

- **Flaw:** <what in the protocol or .context_ledger/ system didn't work>
- **Symptom:** <what happened to the agent — the observable friction>
- **Root cause:** <why the protocol/.context_ledger/ let this happen>
- **Suggested fix:** <concrete change to the package — a step, a pitfall,
  a template, a rule>
- **Status:** open | fixed in package <commit-sha or date>
-->

## 2026-09-11 — Kai / glm-5.3-flash (Session 2)

- **Flaw:** my own conduct — the session never set `office/tasks/current.md` at session start (protocol Step 3) while shipping the protocol; found at closeout when the file was still idle. Also late: the check-in happened only after the user prompted work to begin.
- **Symptom:** for the whole session the board said no task was in progress while a MAJOR release was underway — a peer or crashed-session check would have read the office as idle.
- **Root cause:** jumped from the user's design questions straight into plan mode and implementation; treated the kickoff's Step 2/3 ordering as satisfied because memory had been read.
- **Suggested fix:** package: the pre-commit/exit gates could warn (not block) when `tasks/current.md` was never written during a session whose commits exist. Habit: set current.md immediately after the check-in push, before any plan-mode work.
- **Status:** open — conduct miss, named per the repo's standing rule; tooling suggestion for a future patch.

## 2026-09-11 — Noor / glm-5.3-flash (Session 3)

- **Flaw:** my own conduct, two misses, named per the repo's standing rule. (1) `git add .context_ledger/memory/collaboration/events/` staged the whole directory and committed Kai's (S002) just-completed note event under my commit — in a shared checkout, staging must be per-file. (2) my first `release` event cited only the product commits and carried no `paths`, so it matched no claim and `ledger-collab check` fails on it permanently — the state machine has no supersede path.
- **Symptom:** (1) a peer's event file published by someone else's commit. (2) the integration gate failed twice; the trail held a permanently-red event.
- **Root cause:** directory-granularity staging while sharing the checkout with a live peer; and I had not internalized that a release must either cite the claim ID or carry overlapping `paths`.
- **Suggested fix:** package: `ledger-collab emit release` could default `--paths` from the referenced claim (or refuse to emit a release that matches no claim) — the same condition that fails at integration would then fail at emit time, where it is cheap to fix. For the malformed event there is no in-protocol supersede; repaired by removing the never-referenced file with the supersession documented in the replacement release (git history keeps the original byte-for-byte).
- **Status:** open — conduct miss named; release-defaults-paths is a tooling suggestion for a future patch.

## 2026-09-11 — June / glm-5.3-flash (Session 5)

- **Flaw:** my own conduct miss, named per the repo's standing rule: I never wrote my task into `office/tasks/current.md` at session start (protocol Step 3). `current.md` holds exactly one task and Milo's (S004) live entry occupied it; in collaboration mode I must not clobber a peer's task state, so the file stayed his and my task was declared only through my roster row + claim event.
- **Symptom:** for the first half of the session the one-task board showed Milo's task only; a stale-session check keyed on `current.md` alone would have missed that a second session was live and mid-release.
- **Root cause:** `current.md` is single-slot, but the office legitimately holds concurrent sessions (Kai+Noor, then Milo+June, back to back) — the protocol gives a second session no dedicated place to declare its task.
- **Suggested fix:** package: when the roster shows a live peer, `tasks/current.md` could become a small per-session list, or `ledger-gates checkpoint` could warn when a checked-in session has no `current.md`/claim footprint. The habit that worked here: roster row + claim event with paths, pushed before any product work — from the claim onward the office read correctly.
- **Status:** open — conduct miss named; per-session task slots is a tooling suggestion for a future patch.

## 2026-09-14 — Amari / qwen3.8-flash (Session 10)

- **Flaw:** `ledger-mem lint` (staged and `--tree` modes) flags every `.context_ledger/`-path citation in a tracked product file — but in the package repo, `.context_ledger/` IS the product, so the repo's own front-door docs (`README.md`, the generated `AGENTS.md` digest) are 100% false positives: `lint --tree` reports 87 LEAK lines on the untouched tree, and any commit touching those docs fails the staged lint.
- **Symptom:** the README-rewrite commit failed staged lint (rc=1) on five lines citing the product's own directory name — while the old README already carried ~80 identical lines at HEAD. The strip-on-sight rule (one-way linkage) cannot be honored here: stripping would remove the product's name from its own documentation, and the pre-commit gate (which passed) doesn't call lint, so the failure is loud but toothless for this repo.
- **Root cause:** the one-way-linkage rule assumes the product surface is independent of the ledger. In the repo that *is* the package, the product surface documents the ledger by necessity; the tool has no exclusion for that case.
- **Suggested fix:** package: give lint a documented exclusion for self-documenting product repos — e.g. `lint-exclude|<path>` lines in `memory/workflows/gates.conf`, or auto-exempt files that exist to document the protocol (`README.md`, `AGENTS.md`, `universal-kickoff.md`) when the repo's own `core/` is the vendor source (`ledger-sync status` already detects `source == project root`). The `ADR-[0-9]`, bug-ID, and "per ADR" patterns must stay enforced everywhere — those ARE real leaks in this repo too (1.1.1 fixed one).
- **Status:** open — advisory here; the README commit proceeded on the green pre-commit + integration gates, with the lint rc=1 reported honestly in the report and session entry rather than bypassed silently.
