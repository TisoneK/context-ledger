# Design — Sandbox Continuation Playbook

**Status:** proposal — inputs for core 2.2.1 scoping (supervisor ruling requested, §7)
**Author:** Amani (S020), part 2 · 2026-10-27
**Evidence:** review `office/reviews/2026-10-27-review-s20-sandbox-persistence.md` (part 1 + R4 addendum); four observed resets (R1–R4) on the Z.ai cloud sandbox host; the committed tiered probe (`tests/sandbox-survival-probe.sh`)

---

## 1. Problem

Cloud sandboxes reset without warning. When one does, the next session must
reconstruct enough state to continue as though nothing happened — but today
the protocol says nothing about resets: not how to detect one, not what to
trust afterwards, not which local files are assets and which are traps. Four
resets on one host produced three different survival outcomes (R1: nothing;
R2/R3: tracked files only, clones lost; R4: everything non-ignored,
clones intact). The difference between a five-minute recovery and a
reconstruction-from-Git session is exactly the knowledge in this playbook.

## 2. What survives — the map (evidence-backed, R4-complete)

| Artifact / channel | Survives? | Role in continuation |
|---|---|---|
| **Pushed git history** (GitHub) | **always** — the only cross-reset AND cross-host store | everything the office needs: ledger, code, reviews, backlog |
| Pre-stop `repo.tar` restore | yes, when the pre-stop write lands — full worktree minus scaffold-ignored paths; carries embedded clones' `.git`, nested-gitignored files, untracked-not-ignored, root `.secrets/` | the reason a restore boot *feels* like nothing happened |
| PolarFS mirror of tracked files | yes, with lag (event-coupled, minutes to 40+) | backfills tracked files; `mtime` manifest doubles as a forensics source |
| `upload/` mount | always | user-provided inputs never die |
| Host convenience files (`worklog.md`, `scripts/`) | usually (both channels) | recovery accelerants — never the memory |
| Credential wiring (`credential.helper` in a clone's `.git/config`) | restore boots: yes (rides `repo.tar`); clean boots: gone with the clone | R4: push worked 7 min after boot with zero rewiring |
| Scaffold-ignored paths (`skills/`, `node_modules/`), `/tmp`, outside-project, empty dirs | **never** | reinstall/recreate as needed; never store anything of value there |
| In-memory session state, unpushed commits, `git stash` | **never** | the true loss boundary: only what was never pushed |
| Boot side-effects | n/a | `chmod -R 755` sweep (mode churn + secrets stripped to 755); `.env` rewritten; `skills/` re-extracted |

## 3. How the research fits the office

The office's own continuity was the thing being tested, and it passed:

1. **The ledger is the memory; the host is a cache.** Everything the office
   needs to resume — roster, sessions log, reviews, STATE, backlog, plans,
   environments — lives in `.context_ledger/`, which is tracked and pushed.
   A reset costs at most the current session's unpushed work. S020 parts 1–2
   are the proof: R4 landed mid-research and the session resumed from the
   pushed review + probe alone, losing nothing.
2. **The research artifacts are office artifacts.** The probe is a committed
   test (`tests/`), the findings are a review (`office/reviews/`), the host
   facts are an environment block (`memory/system/environments.md`) — each in
   the surface the protocol already owns. No new storage concept needed.
3. **The protocol's durability rule is now evidence-backed, not folklore.**
   "Not done until pushed" (Rule 6, exit gate) is the single behavior that
   survived every one of the four resets. The playbook's job is to teach the
   *recovery* side of the same rule.
4. **The `worklog.md` convention gets a precise rank.** It is a best-effort
   convenience cache on the host mirror — useful for orientation, never
   authoritative, never load-bearing. Sessions should keep writing it, and
   never depend on it.

## 4. The post-reset runbook (five steps, in order)

1. **Detect.** Small `/proc/uptime` + a fresh `/tmp/boot-timeline.log` (or a
   host-equivalent) = a reset happened this session. Then classify: project
   dir populated → restore boot; bare scaffold → clean boot (expect re-clone).
2. **Verify.** For every repo you expect: `git rev-parse HEAD` and compare
   against the last session's claim (worklog / sessions.md), then `git fetch`.
   Read `git status` for dirt — after a restore boot, expect mode-only churn.
   Never assume unpushed work survived; verify the push state against the
   remote, not against memory.
3. **Harden.** `chmod 600` every secrets file (the boot sweep strips them);
   clear mode churn with `git checkout -- .` or set `core.fileMode false` in
   the clone's local config (it rides `repo.tar`, so it persists across
   resets); confirm `credential.helper` still points at a living script and
   the script's target file exists (re-provision the PAT from the surviving
   copy or the ledger secrets dir if not).
4. **Report.** If the survival probe is dropped on the host, run
   `sh tests/sandbox-survival-probe.sh report <project-root>` and paste the
   matrix into the current review's successor — every reset is a data point.
5. **Resume.** Re-check-in (same codename, next part), read STATE + the last
   session entry, and continue. The office reads as though nothing happened,
   because nothing durable was lost.

Steps 1–3 are mechanical enough for a weak agent; steps 4–5 are the protocol
itself doing what it already does.

## 5. Where each rule lands (surface map)

- **Cloud edition delta** (`core/rules/ai-engineering-protocol.md` — the
  file cloud/sandbox agents are routed to): the five host-agnostic rules —
  (a) the local filesystem is a cache with platform-managed eviction; a push
  is the only durable write; (b) untracked work dies silently; close with a
  clean status; (c) the runbook (§4) as the reset-recovery sequence;
  (d) restore 0600 on secrets after any restore; (e) re-cloning is normal
  recovery, log it in the session entry.
- **Per-project `memory/system/environments.md`:** the host-specific facts —
  hypervisor/mount names, restore-channel internals, sweep behavior, `.env`
  rewrite. Kept out of core by the non-goals ruling (2026-07-13).
- **This repo's `tests/sandbox-survival-probe.sh`:** companion tooling;
  referenced by the cloud delta, not vendored into `core/bin/` yet (§6, Angle D).

## 6. All angles considered for core 2.2.1

- **Angle A — versioning.** The changelog's semver note: wording and fixes
  bump PATCH; new content (sections, pitfalls) bumps MINOR. The delta can be
  shaped either way: clarifications woven into existing sections (push rule,
  secrets handling, exit gate) → **2.2.1 PATCH**; a new "Resets and
  durability" section + runbook → **2.3.0 MINOR**. Recommendation: **2.2.1
  PATCH** with a compact subsection under the existing cloud/platform
  guidance — the runbook is five lines and the rules reinforce what Rule 6
  already says; nothing about the spec or memory layout changes. Supervisor's call.
- **Angle B — surface and self-host.** The delta is written in the package's
  own `core/rules/ai-engineering-protocol.md` (never the vendored
  `.context_ledger/core/`), then self-hosted via `ledger-sync update` — the
  same path every release since 2.0.x took.
- **Angle C — non-goals tension.** The MVP non-goals keep system-specific
  flows out of the universal protocol. The delta must therefore stay
  host-agnostic: no kata/PolarFS/`repo.tar` names in core — those live in
  `environments.md`. The core text speaks of "containerized/sandbox hosts"
  and "whatever local snapshot/restore the platform provides".
- **Angle D — tooling.** Promoting the probe into `core/bin/` (e.g. a
  `ledger-reset report`) would be a feature → MINOR+, and needs a
  host-agnostic design first. Defer; the delta references the probe as a
  repo-level companion test.
- **Angle E — security guidance.** Part 1 §6's persistence claim is
  corrected in the R4 addendum: on tar-restoring hosts, in-repo secrets DO
  survive (nested gitignores are not honored) — non-persistence must never
  be sold as a safety property. The cloud delta keeps the placement rule
  (values only in the ledger secrets dir — leak-prevention via git
  invisibility), adds rotation-after-exposure, and adds the 0600 restore.
- **Angle F — enforcement.** `ledger-guard` could grow a secrets-mode check
  (warn when a secrets file is group/world-readable — exactly what the sweep
  does). Cheap and useful, but it is tooling → 2.3.x unless the supervisor
  pulls it into 2.2.1.
- **Angle G — downstream (LocalMind).** After the core release, LocalMind
  vendors it via `ledger-sync update`, as it did 2.2.0. LocalMind's own open
  items (live-provider reruns, B-2026-10-27-1/-2, P-2026-10-27-1) are
  untouched by this work and unchanged.
- **Angle H — what 2.2.1 must NOT claim.** Pre-stop write failure modes, the
  auto-commit trigger, and snapshot cadence are still open (the probe keeps
  gathering). The delta's wording must say "may lag" / "when the platform
  archive succeeds" — never overclaim, or the next falsification becomes a
  protocol bug.

## 7. Decisions requested from the supervisor

1. **Version:** 2.2.1 (PATCH — guidance woven into existing sections) or
   2.3.0 (MINOR — new "Resets and durability" section + runbook)?
   Recommendation: 2.2.1.
2. **Placement:** the five rules inside the cloud rules file (recommended),
   or as a kickoff.md sidebar for cloud agents?
3. **Hardening steps** (`core.fileMode false`, `chmod 600` restore): protocol
   steps in the cloud delta (recommended — they are cheap and mechanical), or
   per-environment entries only?
4. **Secrets-mode guard** in `ledger-guard` (Angle F): pull into 2.2.1 or
   defer to 2.3.x? Recommendation: defer.
