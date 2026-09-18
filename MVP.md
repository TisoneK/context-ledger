# MVP — Public Release Plan & Feature Roadmap

The plan for taking the `.context_ledger/` workflow public: what ships in the
MVP, what comes after, and which logged flaws each feature retires.
This file is the **single home for advanced/future feature ideas** — when
a session or a flaw entry suggests a feature that's out of scope for a
doc fix, it gets captured here, not lost in chat history.

**Status legend:** `shipped 0.2.0` (landed with the vendored-core
release, 2026-07-14) · `shipped 0.6.0` (peer collaboration) ·
`shipped 0.7.0` (collaboration checks) · `shipped 0.8.0` (lifecycle gates) ·
`shipped 0.9.0` (collaboration reframed as coworkers — the informal `note`
channel, truthful/fast tooling, Windows CRLF fix) · `mvp`
(ships in the first public release) ·
`future` (after MVP) · `exploring` (direction agreed, design open)

---

## The distribution model (the MVP's spine) — `shipped 0.2.0`, evolved

The original plan replaced the per-session clone with a versioned
archive (`context-0.1.0.zip`, unpacked beside the project). **Core 0.2.0 went one step
further: the protocol is *vendored into every project* as
`.context_ledger/core/`** — versioned (`core/VERSION`), checksummed
(`core/MANIFEST.sha256`), documented per release (`core/CHANGELOG.md`),
managed by `core/bin/ledger-sync`. Sessions need no GitHub account, no
PAT, no clone, no network: the protocol is already in the repo.

What remains of the archive idea: **the release artifact for core
updates.** A `context-ledger-X.Y.Z.zip` that unpacks to a core tree is exactly
what `ledger-sync update <path>` accepts as a source — useful for
users who don't clone the package repo at all. Still `mvp`: the release
script that builds, stamps, and names that artifact (the `manifest`
subcommand already exists; zipping + naming doesn't yet).

**Flaws retired by design in 0.2.0:** the package-visibility claim
going stale mid-session, PAT-for-the-package after bootstrap, the
"protocol unreachable mid-session" failure, the endless re-clone loop
(nothing to find or clone), and the structural-vs-data sync ambiguity
(zone ownership replaced the basename rule).

---

## MVP features

### 1. Versioned archive distribution — `mvp` (release script only)
The versioning, changelog, manifest, and update tooling shipped in
0.2.0 (see above). What's left: a release script that zips `core/`
(excluding dev-only files), names the artifact
`context-ledger-<VERSION>.zip`, and publishes it. Open question: distribution
channel (GitHub Releases on a public repo vs. direct share) — decoupled
from the repo's own visibility either way.

### 2. `check` — the mechanical verifier — `mvp`
The protocol's rules are prose; a weak model needs a command. One script
shipped in the package (`bin/check` or `check.sh`) that an agent runs
before every commit, mechanically enforcing what Pitfalls #38–41 and the
bootstrap guards state in words:

- staged diff contains no credential markers (`x-access-token`,
  `github_pat_`, `ghp_`, `gho_`, key-looking strings)
- append-only files (`sessions.md`, `decisions.md`, both
  logs) show additions only (`backlog.md` is exempt — a live queue,
  deletions expected when an item finishes)
- no unfilled `<PLACEHOLDER>`s outside HTML template comments
- no mixed-surface staging (project paths and `.context_ledger/` paths staged
  together)
- bootstrap sanity: `.context_ledger/.git` and protocol editions absent from
  the project's memory dir
- exit-readiness mode (`check --exit`): clean tree, `tasks/current.md`
  cleared, session entry present for today

Open question: portability — POSIX shell + a Python fallback, since
sandboxes vary. The protocol gains one line: "run
`.context_ledger/core/bin/check` before each commit; a failing check blocks
the commit." (Distinct from `ledger-sync`, which manages the vendored
core itself — `check` guards *session output*. It ships inside `core/bin/`
so it, too, travels with every project.)

### 3. Single-source editions — `mvp`
The two editions duplicate ~90% of their text (all 42 pitfalls, the Ten
Binding Rules, the `.context_ledger/` spec); every dual edit risks drift. MVP
restructures to **one core protocol + thin platform deltas** (local /
cloud), with the editions either generated at release-build time (the
zip ships the familiar two files, built from core + delta) or replaced
by explicit "read core, then your platform file" instructions. Build-time
generation preferred — zero change to what agents consume.

### 4. Baked protocol — offline entry per project — `shipped 0.2.0`
Shipped, maximally: the whole core is committed into every project as
`.context_ledger/core/` — editions, schemas, templates, tool. A session can
never find the protocol missing (task2sms Session 2's failure is
impossible by construction), and `memory/core.lock` +
`workflows/active.md` record exactly which core version is in force.

### 5. Session concurrency convention — `shipped 0.6.0`
The protocol now supports opt-in peer collaboration while preserving the
single-agent default. Each collaborating agent uses an isolated git
worktree/branch; immutable one-file-per-event records under
`memory/collaboration/events/` expose claims, proposals, assessments,
agreements, corrections, handoffs, and releases without shared EOF
append conflicts. Overlapping work is resolved by comparing evidence and
agreeing on the best-supported option plus one implementation owner —
there is no timestamp or agent-ID tie-breaker. `tasks/current.md` remains
the lock only when collaboration is not enabled.

The mechanical helpers are `core/bin/ledger-collab` and
`core/bin/ledger-gates`, covering collaboration events, integration checks,
per-turn checkpoints, pre-commit, integration, and exit gates. Product
merges remain peer-reviewed and explicit; the protocol does not silently
merge conflicting code or choose a winner.


---

## Future / advanced (post-MVP)

- **Upgrade flow between package versions** — `shipped 0.2.0` (core),
  `future` (memory-shape migrations) — `ledger-sync update` handles
  core upgrades (semver-gated, verified, memory untouched), and
  `core/CHANGELOG.md` carries per-release migration notes. Still open:
  *memory*-shape changes (a renamed module, a new mandatory memory
  file) need per-release migration steps a session can execute — the
  0.1.x→0.2.0 `MIGRATION.md` is the hand-written prototype of that.
- **Flaw feedback loop for external users** — `exploring` — today flaws
  flow back because the maintainer runs the projects. Public users need
  a path: a `FLAWS-UPSTREAM.md` template they can share, or a public
  issues channel. Constraint: flaw entries can contain project details —
  the template must say what to redact.
- **Community roles** — `future` — `roles/` accepts contributed
  overlays (migration-engineer, perf-engineer, incident-responder…)
  once the overlay contract in `roles/README.md` is versioned.
- **Kickoff generator** — `exploring` — a tiny script or form that
  emits a pre-filled external kickoff (today's manual Pre-Flight), for
  first sessions only; inbound kickoffs already cover the rest.
- **Model-capability profiles** — `exploring` — the Ten Binding Rules
  card is the floor for weak models; a profile system ("strict mode":
  check runs mandatory, smaller step budget, no improvisation clauses)
  could adapt the protocol's freedom to the model driving it.
- **Orchestrator-worker dispatch** — `future` — peer collaboration and
  integration checks are now available across isolated agents, while
  platforms may still use a read-only worker fan-out inside one
  orchestrator session as an optional
  optimization. Workers must publish findings for the orchestrator or
  peers to reproduce before acting on them.
- **Session-based context management (`memory/office/sessions/`)** — `shipped 0.5.0` —
  three-layer model: disposable session detail (`<date>-N/notes.md`) →
  prunable summary (`SUMMARY.md`) → permanent registry (`agents/sessions.md`).
  Context promotion at session end ensures durable facts reach their domain
  files before session directories are cleaned up. The core invariant:
  **permanent context must never depend exclusively on an individual session.**
  Retires the archival gap logged in the feature-scoped-memory design below —
  the session lifecycle concern lands here; the feature-partitioning concern
  (per-feature directories, ledger) remains `exploring`.
- **Feature-scoped memory (`memory/features/`)** — `exploring`, design
  written — full design in `designs/feature-scoped-memory.md` (target:
  core 0.3.0). Partitions memory by the unit that actually has a
  lifecycle: one directory per feature (`manifest.md` update-in-place +
  `notes.md` append-only) plus a permanent append-only
  `features/ledger.md`. The session-management aspect of this design
  shipped in 0.5.0 (`memory/office/sessions/`); the feature-partitioning concern
  (per-feature directories, ledger) remains `exploring`. Includes a
  sanctioned `Feature: none` path for hotfix-sized sessions and folds
  in the missing ADR `Author:` line.
- **Windows-native paths** — `future` — the docs are POSIX-flavored;
  `check` and the kickoff commands need PowerShell equivalents before a
  general public release.
- **Single Python implementation for `core/bin/`** — `exploring` — today
  each of the 7 tools ships as a hand-maintained `sh` + `.ps1` pair (the
  `.cmd` files are thin launchers) — ~5,300 lines across both ports that
  must be kept in parity by hand. `inefficiencies/log.md` (Session ~S0xx,
  "three PowerShell / Git-Bash traps") already logs ~25 minutes lost to
  parity bugs alone: swallowed warnings from PS output-stream capture,
  `Set-StrictMode` scalar-vs-array `.Count`, and heredoc backslash-collapse
  corrupting inserted script text. A single Python implementation would
  run identically on macOS/Linux/Windows and remove the drift class of bug
  entirely. Tradeoff, and why this isn't `mvp`: the package's zero-setup
  promise today relies on `sh` (ships on every POSIX box) and PowerShell
  (ships on Windows 10+) needing no runtime install; requiring Python 3 on
  PATH is a new hard dependency for every consuming project/agent, not
  guaranteed in minimal containers or locked-down CI. Direction not yet
  agreed — captured here per the supervisor's "maybe add to mvp," decided
  to stay `sh`+`.ps1` for now (2026-09-18).

---

## Non-goals (decided, not drifting back in)

- **System-specific flows in the universal protocol** — sandbox venv
  paths, scaffold `.env` quirks, platform pip aliases. These live in each
  project's `system/environments.md` / `inefficiencies/log.md`; agents
  identify and learn them per environment (maintainer ruling, 2026-07-13,
  `flaws/log.md`).
- **The package as a submodule** — the vendored-core model stands;
  submodules re-couple every project clone to package availability,
  which is exactly the failure class vendoring eliminated.
