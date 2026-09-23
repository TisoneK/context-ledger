# Session Summary (compressed history — entries are removable)

One compact entry per session, newest at the bottom. Unlike
`agents/sessions.md` (the formal registry, append-only forever), this
file is a **working summary**: entries may be removed when a session is
no longer useful, and older detail is expected to compress over time.

The purpose is **continuity, not archival completeness**. A future agent
should understand at a glance what important work happened recently,
what significant decisions were made, and where to find detail if needed.

Entries are separated by `---` so agents can parse them as discrete
records.

<!-- TEMPLATE — copy below the last entry:
---
- **YYYY-MM-DD — Session N** — <agent> / <model> — <one-line outcome>.
  <Key decision or discovery, if any.>
  Detail: .context_ledger/memory/office/sessions/YYYY-MM-DD-N/notes.md (or \"summary only\").
-->

<!-- GC GUIDANCE (not part of the template — remove this comment before committing):
- Keep all entries from the last ~10 sessions.
- Older entries: distill key facts into the durable logs (decisions,
  inefficiencies, backlog) if they haven't been promoted already, then
  remove the summary line. The compact entry in agents/sessions.md is
  the permanent record that the session happened.
- Never let SUMMARY.md become another giant history file — if it exceeds
  ~40 lines, it's time to compress.
- A removed summary line MUST have a corresponding permanent entry in
  agents/sessions.md — never delete the only record of a session.
-->

- **2026-09-12 — Session 6** — Ada / glm-5.3-flash — core 1.0.5 shipped (backlog file itself arranged as priority-grouped `ID | Summary` tables with stable `B-<date>-<n>` IDs; workstream view defined as derived-never-stored; legacy checkbox backlogs still closeout-compatible; docs-only) and self-hosted; suite 22/22. Supervisor's mid-session correction redirected the design from a reporting convention to the file arrangement. This office's backlog migrated to the new format. summary only.
- **2026-09-12 — Session 7** — Ines / glm-5.3-flash — core 1.0.6 shipped (check-in-first PATCH: roster sign-in is the session's first write — read roster + last session entry, push, then the deep read; codename claimed by push order, earlier commit wins a collision; main tree settled at the door by conversation; docs-only) and self-hosted; suite 22/22. Entry points regenerated. summary only.
- **2026-09-14 — Session 8** — Zuri / glm-5.3-flash — core 1.1.0 + 1.1.1 shipped (roster Status + Status-detail columns for at-a-glance coordination; a full office auto-closes at the door past office_size/S020, old session numbers never leaking into the fresh office; append-only logs compact — clean sessions append nothing, resolved→archive.md verbatim incl. plans, 3+ repeats roll up; `ledger-mem lint --tree` + strip-on-sight one-way linkage) and self-hosted; suite 22→34 both ports. 1.1.1 stripped a bug ID 1.1.0 left dangling in ledger-sync's own comment. ADR-5; live board migrated to six columns. summary only.
- **2026-09-14 — Session 10** — Amari / qwen3.8-flash — README front-door rewrite shipped (bffbe9b): problem-first, read/update rule as tagline, "What it is not" differentiation added on own judgment over the supplied outside review (whose tagline and invented console demo were rejected); maintainer section kept verbatim. Ran collab-light alongside Nadia's 1.1.2 (note/claim/release, zero overlap). Found: `ledger-mem lint` false-positives on the package's self-documenting docs (87 tree hits) — flaw logged. summary only.
- **2026-09-18 — Session 12** — Leo / claude-sonnet-5 — core 2.0.0 → 2.0.1 shipped and self-hosted: token/context optimization (thin AGENTS.md/CLAUDE.md, phased kickoff.md with a task-scaled routing table, new STATE.md digest + `ledger-state`, edition/playbook split, `ledger-mem prune --apply` + flaws/inefficiencies caps). Live-tested via a real throwaway bootstrap per the supervisor's request; found + fixed 2 bugs (a pre-existing `tests/run-tests.sh` crash with no pwsh, and a `ledger-state` template-comment leak — 2.0.1). ADR-7 records why Common Pitfalls stayed inline while the other five sections became playbooks. summary only.
- **2026-09-19 — Session 14** — Priya / claude-sonnet-5 — core 2.0.2 shipped and self-hosted: URGENT fix for a real collision the supervisor reported directly (agents fighting during initialization). Root cause: 2.0.0's AGENTS.md rewrite dropped the standalone check-in-before-analysis directive that was the deliberate weak-agent floor. Restored to AGENTS.md/CLAUDE.md, strengthened kickoff.md's phase-execution guidance, added a regression test so it can't silently break again. Verified on a fresh bootstrap. summary only.
- **2026-09-19 — Session 15** — Omar / claude-sonnet-5 — core 2.0.3 shipped and self-hosted: supervisor audit of 2.0.0 beyond the 2.0.2 collision fix. Diffed 2.0.0-2.0.2 against v1's 1.2.0 directly; fixed a 3-release-old broken `pitfalls.md` routing reference, restored 2 v1 rules deleted with no replacement, extended the weak-agent floor past just check-in (office-close trigger, secrets, commit-surface split, push-before-done), and hardened the playbook routing default so Code Review stays unconditional. Tests 29→40. Found + parked (not fixed) a much larger `ledger-mem lint --tree` false-positive scope. summary only.
- **2026-09-23 — Session 16** — Ilya / deepseek/deepseek-flash — core 2.0.4 shipped and self-hosted: the 2.0.3 ps1 ports were unparseable on Windows (a `$Label:` scope-qualified reference broke both engines; non-ASCII bytes are a 5.1-only parse failure because 5.1 decodes BOM-less scripts with the system codepage). Ports are pure ASCII now and emit non-ASCII from code points; verify checks every engine on PATH and fails a non-ASCII port on any host; STATE.md is byte-identical across sh/pwsh/5.1. Suite 60 → 63. Also closed a pre-existing hyphen/em-dash drift between the ports. summary only.
