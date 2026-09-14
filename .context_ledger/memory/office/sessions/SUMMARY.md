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
  Detail: .context_ledger/memory/sessions/YYYY-MM-DD-N/notes.md (or \"summary only\").
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

- **2026-09-10 — Session 1** — Ada / glm-5.3-flash — core 0.22.0 shipped (collab events as JSON + backlog closeout sweep); ledger self-hosted with the release-sync rule. First solo claim→release cycle validated on the new board. summary only.
- **2026-09-11 — Session 2** — Kai / glm-5.3-flash — office architecture shipped as core 1.0.0 (live memory/office/, verbatim freeze at close, permanent accomplishments records, during-sync migration, checkpoint nudge); self-hosted, repo memory grouped into the office; sh+ps1 verified e2e. summary only.
- **2026-09-11 — Session 3** — Noor / glm-5.3-flash — core 1.0.1 shipped (gate verdict can't be cleared by a piped consumer; verify parse-checks every port; package test suite) and self-hosted; suite 11/11. Ran alongside Kai (S002) in the shared checkout — cp1252 encoding fix deferred to 1.0.2. summary only.
- **2026-09-11 — Session 4** — Milo / glm-5.3-flash — core 1.0.3 shipped (gate-teeth fix, second half: Run-One captures child stdout and judges the verdict BEFORE re-emitting; Invoke-ChildScript `$?` ordering hardened; sh port unaffected; suite 22/22 on both ports) and self-hosted. Closed the chatty-failing-child case carried from the fleet-sync evidence (S443/S467/S468). summary only.
- **2026-09-11 — Session 5** — June / glm-5.3-flash — core 1.0.4 shipped (session reports specified by voice, not a mandated skeleton: Step 13 both editions + reviews/README + feature-engineer overlay; docs-only) and self-hosted; suite 22/22. Shipped from an isolated worktree while Milo (S004) was live in the shared checkout; rebased onto his 1.0.3. summary only.
- **2026-09-12 — Session 6** — Ada / glm-5.3-flash — core 1.0.5 shipped (backlog file itself arranged as priority-grouped `ID | Summary` tables with stable `B-<date>-<n>` IDs; workstream view defined as derived-never-stored; legacy checkbox backlogs still closeout-compatible; docs-only) and self-hosted; suite 22/22. Supervisor's mid-session correction redirected the design from a reporting convention to the file arrangement. This office's backlog migrated to the new format. summary only.
- **2026-09-12 — Session 7** — Ines / glm-5.3-flash — core 1.0.6 shipped (check-in-first PATCH: roster sign-in is the session's first write — read roster + last session entry, push, then the deep read; codename claimed by push order, earlier commit wins a collision; main tree settled at the door by conversation; docs-only) and self-hosted; suite 22/22. Entry points regenerated. summary only.
- **2026-09-14 — Session 8** — Zuri / glm-5.3-flash — core 1.1.0 + 1.1.1 shipped (roster Status + Status-detail columns for at-a-glance coordination; a full office auto-closes at the door past office_size/S020, old session numbers never leaking into the fresh office; append-only logs compact — clean sessions append nothing, resolved→archive.md verbatim incl. plans, 3+ repeats roll up; `ledger-mem lint --tree` + strip-on-sight one-way linkage) and self-hosted; suite 22→34 both ports. 1.1.1 stripped a bug ID 1.1.0 left dangling in ledger-sync's own comment. ADR-5; live board migrated to six columns. summary only.
