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

## 2026-09-14 — Zuri / glm-5.3-flash (Session 8)

- **Flaw:** `ledger-mem prune`'s archive-eligibility heuristic over-matches. Its closed-marker regex (`superseded|RESOLVED|fixed in package|…`) scans every line of a segment, so it flags (a) the leading `## ADR-N`/log **template comment** (whose placeholder literally reads "superseded by ADR-M") and (b) any real entry whose body merely *mentions* the word — e.g. ADR-5, written to describe the compaction rule, contains "resolved/superseded entries move verbatim…". On the fresh core 1.1.0 `plans/decisions.md`, both live ADRs were reported "archive-eligible" though every one is `accepted`.
- **Symptom:** `prune` reported 2 of 6 decisions archive-eligible; `--list` named the template comment + ADR-5. Acting on it would have wrongly archived a current ADR.
- **Root cause:** keyword match against arbitrary body text + no exclusion of the seeded template comment block; the "closed" signal should be the entry's own `**Status:**` line, not any occurrence of the word.
- **Suggested fix:** package (both `ledger-mem` + `.ps1`): scope the closed-marker to the entry's `**Status:**` line only (or `^-\s*\*\*Status:\*\*.*(superseded|resolved)`), and skip the `<!-- … -->` template preamble when segmenting so the `ADR-N` placeholder is never a candidate.
- **Status:** open — advisory-only, so no data was at risk; logged as `Upstream: candidate` for a future PATCH to the prune heuristic.

## 2026-09-11 — Kai / glm-5.3-flash (Session 2, second addendum)

- **Flaw:** my own staging mistake — my 1.0.0-closeout commit (01e76ac) used `git add .context_ledger/memory/` and swept an uncommitted leftover into the commit: Noor's (S003) roster row, which her clock-out (1b894f7) had already removed correctly. The board then showed a peer in the office who had left.
- **Symptom:** the committed roster claimed Noor was present after her session ended; caught this session when checking the board before re-checking in, and traced via the roster's commit history (her clock-out removed the row; no later commit touched the file — the row lived on uncommitted in her working tree until my directory-wide add swept it).
- **Root cause:** directory-wide `git add` on the memory zone, where peer sessions leave uncommitted state. The 0.20.0 additive-edit lesson (your diff shows exactly your row) applies to staging too.
- **Suggested fix:** habit + package: stage named files after reviewing `git diff` (never `git add <dir>` under `.context_ledger/memory/`); `ledger-mem check` could warn when a committed roster row belongs to a session whose clock-out commit already exists.
- **Status:** fixed here — her stale row removed in this session's check-in commit (verified: her clock-out commit + Session 3 entry prove she left); logging rule honored.

## 2026-09-11 — Milo / glm-5.3-flash (Session 4)

- **Flaw:** the 1.0.1 gate-verdict fix was incomplete. It closed the piped-consumer case (`failing-cmd | tee`), but `Run-One` still ran the gated command inline, so a configured command that PRINTS to stdout and exits nonzero returned `@(lines..., $false)` — `-not` on a non-empty array never registered the failure, and the gate printed `FAILED (N)` and then `GATE PASSED` with rc=0. The archived 1.0.1 entry's "the rc is the verdict again" was therefore premature; the interim "read gate stdout, never trust rc on Windows" rule stayed necessary through 1.0.2.
- **Symptom:** fleet projects re-verified the flaw open on 1.0.0 (Asha, S467) and on 1.0.2 (Amir, S468, three evidence legs including a real pre-commit `FAILED (1)` → `GATE PASSED`). The 1.0.1 package regression never caught it because it exercised `cmd /c exit 3` — a silent failure, exactly the case that already worked. The maintainer repo picked the flaw up from the fleet-sync evidence report and confirmed it by structural read + a minimal probe before patching.
- **Root cause:** PowerShell functions return everything on their output pipeline. `Invoke-ChildScript` already used the correct capture-and-host-stream pattern; `Run-One` never got it — the file's own comments documented the trap for `Log` while missing the child-command path.
- **Suggested fix (applied in core 1.0.3):** capture the child's stdout (`$out = & ([scriptblock]::Create($Text))`), judge the verdict BEFORE re-emitting — the `Write-Host` loop resets `$?`, so the naive capture patch would swap one mask for another — then re-emit on the host stream. Same-class hardening: `Invoke-ChildScript`'s `$?` fallback moved before its re-emit loop. Regression in tests/run-tests.sh: a chatty failing command must fail the gate with output visible and the `FAILED (N)` verdict line asserted, never the wrapper rc alone (suite 14 → 22, both editions). The sh port is unaffected (real child shell, exit propagates, stdout never passes through a function return).
- **Status:** fixed in package core 1.0.3 (fix 6b710d4, release 2609f75, self-hosted 5ad5955). The interim rc rule retires per project once its vendored core reaches 1.0.3.

## 2026-09-11 — June / glm-5.3-flash (Session 5)

- **Flaw:** my own conduct miss, named per the repo's standing rule: I never wrote my task into `office/tasks/current.md` at session start (protocol Step 3). `current.md` holds exactly one task and Milo's (S004) live entry occupied it; in collaboration mode I must not clobber a peer's task state, so the file stayed his and my task was declared only through my roster row + claim event.
- **Symptom:** for the first half of the session the one-task board showed Milo's task only; a stale-session check keyed on `current.md` alone would have missed that a second session was live and mid-release.
- **Root cause:** `current.md` is single-slot, but the office legitimately holds concurrent sessions (Kai+Noor, then Milo+June, back to back) — the protocol gives a second session no dedicated place to declare its task.
- **Suggested fix:** package: when the roster shows a live peer, `tasks/current.md` could become a small per-session list, or `ledger-gates checkpoint` could warn when a checked-in session has no `current.md`/claim footprint. The habit that worked here: roster row + claim event with paths, pushed before any product work — from the claim onward the office read correctly.
- **Status:** open — conduct miss named; per-session task slots is a tooling suggestion for a future patch.

## 2026-09-12 — Ines / glm-5.3-flash (Session 7)

- **Flaw:** the protocol sequenced the roster check-in after the startup read — Step 3's read order ran the memory files before the sign-in bullet, and the ENTRY rule ("do not edit any file until Phase 1 is complete") read as backing for deferring it. A worker launched by the supervisor spends the long read on protocol and product code first, so the board stays empty while they think.
- **Symptom:** two workers launched together both see an empty office, each concludes they are alone, and each takes the same codename/session number they thought of at the door; when they finally notice each other they are strangers mid-analysis arguing over who takes the main tree. The supervisor reported the exact scenario ("workers should check in at the entrance not after working").
- **Root cause:** presence was sequenced as a pre-work formality rather than the session's first write — the push, the only thing peers can actually see, came after everything interesting.
- **Suggested fix (applied in core 1.0.6):** the check-in is the session's FIRST write — signing needs exactly two files (roster + last session entry), so read those, push, then do the deep read; ENTRY names the check-in row the one sanctioned edit inside Phase 1. The push claims the codename (whoever's check-in commit is already on origin keeps it; on a collision the earlier commit wins and the later worker renumbers their own row only — never drops a peer's row). The main tree is settled at the door by conversation: work already in flight keeps it, the other worker isolates on a branch/worktree, both declare the shared session/issue. Shipped to both editions, the kickoff Step 2 (retitled "Sign in at the door"), the AGENTS digest rule 5, the roster template preamble, the vendored README, and the schema (roster spec, reading order, office lifecycle).
- **Status:** fixed in package core 1.0.6 (release bd39226, self-hosted 21ecc1c).

## 2026-09-14 — Amari / qwen3.8-flash (Session 10)

- **Flaw:** `ledger-mem lint` (staged and `--tree` modes) flags every `.context_ledger/`-path citation in a tracked product file — but in the package repo, `.context_ledger/` IS the product, so the repo's own front-door docs (`README.md`, the generated `AGENTS.md` digest) are 100% false positives: `lint --tree` reports 87 LEAK lines on the untouched tree, and any commit touching those docs fails the staged lint.
- **Symptom:** the README-rewrite commit failed staged lint (rc=1) on five lines citing the product's own directory name — while the old README already carried ~80 identical lines at HEAD. The strip-on-sight rule (one-way linkage) cannot be honored here: stripping would remove the product's name from its own documentation, and the pre-commit gate (which passed) doesn't call lint, so the failure is loud but toothless for this repo.
- **Root cause:** the one-way-linkage rule assumes the product surface is independent of the ledger. In the repo that *is* the package, the product surface documents the ledger by necessity; the tool has no exclusion for that case.
- **Suggested fix:** package: give lint a documented exclusion for self-documenting product repos — e.g. `lint-exclude|<path>` lines in `memory/workflows/gates.conf`, or auto-exempt files that exist to document the protocol (`README.md`, `AGENTS.md`, `universal-kickoff.md`) when the repo's own `core/` is the vendor source (`ledger-sync status` already detects `source == project root`). The `ADR-[0-9]`, bug-ID, and "per ADR" patterns must stay enforced everywhere — those ARE real leaks in this repo too (1.1.1 fixed one).
- **Status:** open — advisory here; the README commit proceeded on the green pre-commit + integration gates, with the lint rc=1 reported honestly in the report and session entry rather than bypassed silently.
