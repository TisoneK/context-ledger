# Inefficiency Log (append-only — real friction only)

Append a block **only when something actually slowed you down** — a clean
session appends nothing (its `agents/sessions.md` entry is the record;
"none this session" blocks are noise, not history). But when something
bit you, the block is mandatory and honest: friction you absorb silently
is friction the next agent hits blind.

Most inefficiencies are project-local (an environment quirk, a one-off
cost) and stay here. When one is actually **protocol-level** — the core
workflow itself made you slower and every project would hit it — mark it
`Upstream: candidate`. `ledger-sync harvest` collects those (and open
`flaws/`) into the package for an upstream fix. Unmarked entries are
never harvested.

Append-only, but compactable — the log never grows without bound:

- **Resolved entries move verbatim** to cold storage: once an entry is
  explicitly marked `RESOLVED` / `superseded` / fixed, cut it unchanged
  into `archive.md` in this directory so startup reads only the live
  entries. Age alone never makes an entry eligible.
- **Repeats roll up:** when 3+ entries describe the same recurring thing
  (same failing tool, same root cause), append ONE consolidated
  `Recurring` entry — the pattern, how many times, the current
  workaround — and move the individual entries verbatim into
  `archive.md`. The live log keeps the pattern, not the repeats.

`ledger-mem prune` reports log sizes, archive-eligible entries (`--list`
names them), and roll-up candidates.

<!-- TEMPLATE — copy below the last entry:
---
## YYYY-MM-DD — <agent> / <model>
- **Problem:** <what went wrong or was slower than it should be>
- **Cost:** <rough time/effort wasted>
- **Cause:** <root cause if known>
- **Workaround / fix:** <what worked, or "unresolved">
- **Prevent next time:** <protocol/context change that would have avoided it>
- **Upstream:** candidate  ← add this line ONLY for protocol-level friction
  worth a core fix; omit entirely for project-local friction.
-->

## 2026-09-11 — Noor / glm-5.3-flash
- **Problem:** shipping two independent `core/` fixes in one release against the "manifest regen in the same commit" rule — the manifest hashes the whole tree, so regenerating it for commit 1 would have hashed commit 2's still-uncommitted files, and a checkout of commit 1 would have failed verify. Plus a test-harness slip: assigning a multi-word command with `VAR="x" cmd` prefix syntax runs only the assignment, not the command.
- **Cost:** one juggling cycle per problem (~10 minutes total): copy the sibling edit aside, restore to HEAD, regen, commit, copy back, regen; one failed test-suite run.
- **Cause:** whole-tree manifest + sequential dependent commits; sh test driver built a command as an assignment prefix instead of a wrapper function.
- **Workaround / fix:** copy not-yet-committed core files to /tmp, `git checkout --` them, regen + commit fix 1, copy back, regen + commit fix 2 (no stash — a peer's uncommitted files were in the tree). Test drivers use wrapper functions.
- **Prevent next time:** keep one core change in flight at a time (edit → verify → regen → commit → next); the cp-aside dance is the documented fallback when two fixes must ship in one release.

## 2026-09-11 — Milo / glm-5.3-flash
- **Problem:** my first behavioral probe of the Run-One fix ran the sh port under Git Bash instead of the ps1 port — and MSYS argument mangling made `cmd /c "echo x & exit /b 1"` start cmd.exe interactively (banner + prompt, read EOF, exit 0), so the probe showed a silent pass that proved nothing about either port. Two command cycles wasted before rerunning against the ps1 port directly.
- **Cost:** ~2 command cycles (~5 minutes).
- **Cause:** probed through the runner I had in context (the sh port) instead of the port that carries the flaw; compound-command quoting through sh → cmd is a second uncontrolled variable.
- **Workaround / fix:** reran against `powershell.exe -NoProfile -File ledger-gates.ps1` on a scratch project (cygpath for the Windows path); chatty failing child → `FAILED (1)` + `GATE FAILED` + rc=2 as wanted.
- **Prevent next time:** a probe goes to the port that carries the flaw, one variable at a time — the mirror image of the S468 scratch-repo false closure (right repo family, wrong port).

## 2026-09-11 — June / glm-5.3-flash
- **Problem:** three coordination hazards while shipping alongside a live peer (Milo, S004) in one shared checkout: (1) the whole-tree manifest regen would have hashed his uncommitted `core/bin/ledger-gates.ps1` into my release commit; (2) both sessions had declared PATCH version numbers (1.0.3 was his); (3) my check-in push fast-forwarded origin over his three local, not-yet-pushed release commits — origin sat behind the shared checkout's HEAD, so my push published his 1.0.3 before his own push did.
- **Cost:** ~20 minutes of setup and checking: isolated worktree + branch off origin/main so every manifest regen and the self-host copy ran against clean HEAD; a fetch-and-inspect cycle before each push.
- **Cause:** the shared checkout is one working tree for two sessions — git operations there (regen, commit, push) see each other's uncommitted and unpushed state by design.
- **Workaround / fix:** worktree + branch, claim event posted first; the version slot resolved itself when his 1.0.3 landed mid-session (rebased, shipped 1.0.4); the swept-commits publication turned out harmless — his release was complete and consistent (verify green, suite 22/22).
- **Prevent next time:** any session touching `core/` while a peer is live works out of a worktree from the start; fetch before every push; treat origin, not the shared tree, as the source of truth for what is already public.

## 2026-09-12 — Ines / glm-5.3-flash

- **Problem:** one `git push` failed with "Could not resolve host: github.com" immediately after the core 1.0.6 release commit — transient DNS on the workstation; a single retry seconds later pushed cleanly.
- **Cost:** one failed command cycle (~1 minute).
- **Cause:** network blip, not a protocol or tool issue.
- **Workaround / fix:** retried the push; it succeeded at once.
- **Prevent next time:** none needed — a transport-level push failure with an unchanged tree is retry-safe; if it had persisted, that is machine config for the supervisor, not something to work around.
