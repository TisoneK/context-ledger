# Consolidated Flaws — Archive (retired, resolved/closed)

Resolved, closed, and superseded entries moved verbatim out of
`flaws/log.md` so the active log holds only what is still open. Nothing is
rewritten here — entries are byte-identical to how they were logged, and
stay fully grep-able. This is the sanctioned "compaction, not hoarding"
move (see memory decisions log). Retired by Mateo (S023), 2026-11-26.

---
## 2026-07-11 — Super Z / GLM-4.5 (consolidated from package review, Session 4)

- **Flaw:** `roles/README.md` referenced "Phase 5 (Steps 15–17)" but the base editions have only 4 phases. Steps 15–17 are in Phase 4 (Report & Context), not a separate Phase 5.
- **Symptom:** An agent trying to map role instructions to edition steps would look for a Phase 5 that doesn't exist, causing confusion about which phase the memory-update steps belong to.
- **Root cause:** The roles/README.md was written with a 5-phase mental model, but the editions were structured into 4 phases. The phase label was added for clarity but introduced a mismatch.
- **Suggested fix:** Change "Phase 5 (Steps 15–17)" → "Phase 4, Steps 15–17" (or drop the phase label entirely and reference steps by number only).
- **Source:** Package review by Super Z / GLM-4.5, Session 4
- **Status:** fixed in this commit — `roles/README.md` now says "Phase 4, Steps 15–17"

---
## 2026-07-11 — Super Z / GLM-4.5 (consolidated from package review, Session 4)

- **Flaw:** `localmind-review.md` sat at the package root, making it look like a review of the `.context` package itself rather than an example deliverable from a project session.
- **Symptom:** A new visitor to the repo (human or agent) might confuse the example review with a review of the protocol package, misreading LocalMind-specific findings as protocol findings.
- **Root cause:** No `examples/` directory existed; the example file was placed at the root for convenience. The README explained it was an example, but the file's location didn't reinforce that.
- **Suggested fix:** Move to `examples/localmind-review.md`. Create the `examples/` directory as the home for sample deliverables.
- **Source:** Package review by Super Z / GLM-4.5, Session 4
- **Status:** fixed in this commit — moved to `examples/localmind-review.md`, README link updated

---
## 2026-07-11 — Super Z / GLM-4.5 (consolidated from package review, Session 4)

- **Flaw:** The quickstart doc (`context-workflow-quickstart.md`) existed in the user's local uploads but was never committed to the package repo. New users/agents had no entry point explaining the two-repo mental model and bootstrap steps.
- **Symptom:** A new user cloning `TisoneK/.context` for the first time sees protocol files, a skeleton, roles, and an example review — but no "how do I actually use this?" guide. They have to read the README and infer the workflow.
- **Root cause:** The quickstart was written as a separate doc but never added to the repo. The README covers usage briefly but doesn't walk through the full two-repo model.
- **Suggested fix:** Commit as `QUICKSTART.md` at the package root. Add to the README contents table.
- **Source:** Package review by Super Z / GLM-4.5, Session 4
- **Status:** fixed in this commit — added as `QUICKSTART.md`, linked from README

---
## 2026-07-11 — Super Z / GLM-4.5 (consolidated from package review, Session 4)

- **Flaw:** The cloud edition's `secrets/github-pat` guidance didn't distinguish cloud-sandbox persistence (session-only) from local-agent persistence (survives across sessions). The text said the file "dies with the sandbox" — correct for cloud, misleading for local agents who might read the cloud edition for reference.
- **Symptom:** A local agent reading the cloud edition might wrongly conclude that `.context/secrets/` is always ephemeral, missing that on a local machine the file persists and can be reused across sessions.
- **Root cause:** The guidance was written from the cloud-sandbox perspective only. The two persistence models (cloud ephemeral vs local persistent) weren't called out as a distinction.
- **Suggested fix:** Add explicit cloud-vs-local sub-bullets under the `secrets/github-pat` guidance: cloud = session-only convenience, local = persists across sessions.
- **Source:** Package review by Super Z / GLM-4.5, Session 4
- **Status:** fixed in this commit — `ai-engineering-protocol.md` Step 1 now has cloud/local sub-bullets

---
## 2026-07-11 — Super Z / GLM-5.2 (Session 5) — UPDATE: flaws 1–4 fixed

Flaws 1–4 (consolidated from LocalMind Session 3, GitHub Copilot) are
now **fixed in this commit**. All four suggested fixes applied to both
protocol editions:

- **Flaw 1 (binding instruction):** Fixed. Step 3 now says "Reading
  `workflows/active.md` is a binding instruction, not passive
  documentation." Added as Pitfall #27 in both editions.
- **Flaw 2 (protocol source):** Fixed. `workflows/active.md` template
  now has a `Protocol source` field with the GitHub URL.
- **Flaw 3 (no-task-too-small):** Fixed. Protocol preamble now says
  "No task is too small for Phase 1." Added as Pitfall #28.
- **Flaw 4 (two surfaces):** Fixed. Both editions now have a "Two
  Surfaces — Know Which One You're On" section before Phase 1.

---
## 2026-07-11 — Super Z / GLM-5.2 (consolidated from LocalMind, Session 5)

- **Flaw:** Agents are asked to record their model identity in `.context/system/ai-models.md` and `agents/sessions.md`, but the protocol gave them no reliable way to determine it. The system prompt doesn't state the model version, and the protocol's Pre-Flight said "agent fills in — records best self-description." This led the agent to guess "GLM-4.5" in Session 1, which propagated verbatim through Sessions 2–4. The actual model was GLM-5.2.
- **Symptom:** All `.context/` entries from Sessions 1–4 recorded the wrong model (GLM-4.5 instead of GLM-5.2). The user caught it in Session 5 by asking "why did you say 4.5?"
- **Root cause:** The protocol treated model identity as something the agent could self-determine. It can't — system prompts don't reliably state the model version. The user knows (they selected it in the UI); the agent doesn't.
- **Suggested fix:** Move Agent Identity from "agent fills in" to "user fills in — agent copies, never guesses." Add a pitfall: "Never guess your own model version. If it's not in Pre-Flight, ask once. If the user doesn't know, record 'unknown'."
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 5
- **Status:** fixed in this commit — Agent Identity section rewritten in both editions; Pitfall #25 added.

---
## 2026-07-11 — Super Z / GLM-5.2 (consolidated from LocalMind, Session 5)

- **Flaw:** The protocol didn't clearly mark session entry, phase transitions, or exit. Agents didn't know where to start (Copilot jumped to editing before reading the workflow), didn't know how to transition between phases, and didn't know how to end (Copilot had to be reminded to commit and push). This is the root cause behind flaws 1–4 — they're all symptoms of missing lifecycle markers. The user explicitly flagged this as "the biggest flaw."
- **Symptom:** Copilot (Session 3) didn't know where to start (skipped Phase 1), didn't know how to end (user had to remind it to commit/push). The protocol had 19 steps but no explicit "you are done when..." checklist.
- **Root cause:** The protocol had 19 steps in 4 phases but no explicit ENTRY marker (what to do first), no TRANSITION markers (when to move between phases), and no EXIT checklist (what must be true before the session is done). An agent could finish the work but not realize it hadn't pushed, because there was no checklist saying "push is part of done."
- **Suggested fix:** Add a "Session Lifecycle — Entry, Transitions, Exit" section to both editions, before Phase 1. ENTRY: read Two Surfaces + Pre-Flight first, don't edit until Phase 1 is done. TRANSITIONS: phase-boundary conditions. EXIT: mandatory checklist (all fixes committed AND pushed, report committed AND pushed, .context/ updated committed AND pushed, PAT unset, chat summary delivered). Add: "If the user has to remind you to commit or push, the protocol failed — log it as a flaw."
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 5
- **Status:** fixed in this commit — both editions now have the Session Lifecycle section with ENTRY/TRANSITIONS/EXIT. Pitfall #26 added.

---
## 2026-07-11 — Super Z / GLM-5.2 (consolidated from LocalMind, Session 7) — PAT leak in chat summary

- **Flaw:** The protocol says "never write the PAT to any file" and "never echo secret values from `secrets/`," but it never explicitly says "don't include the PAT value in chat output or rotation reminders." An agent following the Exit checklist's "remind the user to rotate the PAT" step can reasonably include the full token value — defeating the secret-handling rules. The PAT lives as an env var, not a `secrets/` file, so the `secrets/README.md` "never echo a value" rule doesn't feel applicable.
- **Symptom:** Session 7's final chat summary included the full PAT in plaintext: "⚠️ Rotate the PAT — `github_pat_11ASCEY4Q0n1QCPOjmffJy_...` was used this session and is now unset." The agent's intent was good (reminding the user to rotate), but including the actual value leaked it into the chat transcript, which may be logged, shared, or screenshotted.
- **Root cause:** The protocol's secret-handling rules are scoped to files and `secrets/` values, not to the PAT env var in chat output. The Exit checklist says "remind the user to rotate the PAT" but doesn't say "reference the token by last 4 characters, never the full value." The agent reasoned: "the user pasted it, so they know it; including it makes the reminder more useful." That reasoning is understandable but wrong — the chat transcript is not a secure channel.
- **Suggested fix:** Add to both protocol editions, in the PAT section: "Never echo the PAT value in chat output. This includes rotation reminders, error messages, and 'for your reference' notes. The user pasted it; they know it. Your reminder should say 'Rotate the PAT' — not 'Rotate the PAT: `github_pat_...`'. If you need to reference which token, use the last 4 characters: 'Rotate the PAT ending in `5KV`.' The full value must never appear in your output, in any form." Add as a pitfall in both editions.
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 7
- **Status:** fixed in this commit — both editions now have the rule + pitfall

---
## 2026-07-11 — Super Z / GLM-5.2 (Session 8) — UPDATE: Session 7 flaws fixed

Flaws consolidated from LocalMind Session 7 are now **fixed in this commit**:

- **blob/ vs raw/ URL:** Fixed. `context-skeleton/workflows/active.md`
  template now has separate "Protocol source (raw)" and "Protocol
  source (blob)" fields, plus a fallback note. LocalMind's
  `workflows/active.md` updated too.
- **Append-only dedupe exception:** Fixed. `context-skeleton/README.md`
  Rule 2 now has an exception for byte-identical duplicates. LocalMind's
  `.context/README.md` updated too. Applied to the duplicate Session 6
  entry in LocalMind's `agents/sessions.md`.
- **PAT leak in chat:** Fixed. Both protocol editions now have the
  "Never echo the PAT value in chat output" rule (in the PAT section
  for cloud; in the secrets rule for local) and Pitfall #29.

---
## 2026-07-11 — Super Z / GLM-5.2 (consolidated from LocalMind, Session 8) — pull-before-inspect gap

- **Flaw:** The protocol says "pull before starting work" (Step 2), but when a user tells an agent mid-session to "check what another session did" or "pull changes," the agent doesn't have an explicit rule to pull first. The agent may inspect stale local state and report wrong information.
- **Symptom:** When told "maybe check what the session did first," the agent jumped straight to `git show` on the latest local commit, assuming local was current. Remote was ahead. The inspection was performed on stale state.
- **Root cause:** The protocol's pull rule is scoped to session start (Step 2), not to any point where remote may have moved ahead. There's no rule for mid-session sync.
- **Suggested fix:** Add: "Before inspecting another agent's work, or whenever the user references work you haven't seen — fetch first. If remote is ahead, pull before inspecting." Add as a pitfall.
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 8
- **Status:** fixed in this commit — both editions updated

---
## 2026-07-11 — Super Z / GLM-5.2 (consolidated from LocalMind, Session 8) — rhetorical yes/no questions

- **Flaw:** The Zero-Interruption Principle says "does not ask the user questions between steps," but agents read this as "don't ask for *clarification*" while still asking for *permission* on the default next step. Two models (GLM-5.2 and DeepSeek V4 Flash Free) exhibited the same pattern → it's a protocol gap, not a model trait.
- **Symptom:** GLM-5.2 asked "Want me to proceed with all 5, or just some?" three times in a row, despite the user having repeatedly said "fix everything." The agent proposes → user says yes → agent does it. Should be: agent does it.
- **Root cause:** The Zero-Interruption Principle is stated generally but doesn't explicitly call out asking-for-permission as a failure mode. Agents draw a false distinction between "clarification" (which they know not to ask) and "permission" (which they think is polite).
- **Suggested fix:** Add Pitfall #30: "Don't ask for permission on the default next step. If the action is what the protocol already prescribes, do it and report. Only ask when there's genuine ambiguity."
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 8. Originally logged as a DeepSeek-specific observation in Session 3; graduated to a protocol flaw after GLM-5.2 exhibited the same pattern in Session 8.
- **Status:** fixed in this commit — Pitfall #30 added to both editions

---
## 2026-07-11 — Claude Code / claude-fable-5 (package repo session)

- **Flaw:** A review finding was applied without verifying it against the document it cited. The review claimed "the editions have 4 phases, not 5" — both editions have six. The applied fix changed `roles/README.md`'s correct "Phase 5 (Steps 15–17)" to "Phase 4, Steps 15–17", pointing the mandatory memory-update rule at the Report phase (Steps 13–14).
- **Symptom:** `roles/README.md` carried a wrong phase label until the next session re-verified the phase structure (`grep "^### Phase"` in both editions) and reverted it.
- **Root cause:** "Verify before trusting" covers `.context/` entries vs the codebase, but no rule required verifying a review's claims against the referenced file before applying its fixes.
- **Suggested fix:** Pitfall: "Don't apply a review finding without reproducing it — grep the referenced section first."
- **Source:** TisoneK/.context — package repo session, 2026-07-11
- **Status:** fixed in this commit — Phase 5 reference restored + Pitfall #31 added to both editions

---
## 2026-07-11 — Claude Code / claude-opus-4-8 (consolidated from vert, Session 1)

- **Flaw:** The universal kickoff's Step 0 was written cloud-first — PAT setup, cloning the project repo, unconditional `git config`, a token-strip dance on push, and "don't unset `GIT_TOKEN`." A local IDE agent already sitting inside the already-cloned repo had to mentally translate every step, and "clone the project repo" (Step 0b) was a no-op that muddied where to work. Compounding it: the kickoff was a user's local (Desktop) artifact never committed to the package — so a fix to it couldn't reach other users/agents (same pattern as the earlier `QUICKSTART` flaw).
- **Symptom:** During vert Session 1 (a local Claude Code session), the agent had to reconcile the kickoff's clone-based flow against the local protocol edition ("repo is already local, don't clone"), and only avoided the redundant project clone by deferring to the local edition.
- **Root cause:** One kickoff served both editions, but its Step 0 assumed the cloud flow and never branched on "local agent, repo already present." And the kickoff lived only on the user's machine, outside version control.
- **Suggested fix:** (1) Branch Step 0 on agent type — a Local path (confirm you're in the repo, never re-clone, no PAT, don't touch git identity unless empty, clone only the package as a sibling) and a Cloud/sandbox path (the original PAT + clone-both flow); mark every PAT/`GIT_TOKEN` reference cloud-only; normalize paths so `../.context-package` (a sibling of the project) resolves for both. (2) Commit the kickoff into the package so the fix is versioned and shared.
- **Source:** TisoneK/vert — `.context/flaws/log.md`, Session 1 (2026-07-11)
- **Status:** fixed in this commit — `universal-kickoff.md` added to the package with Step 0 branched local/cloud, PAT refs marked cloud-only, a shared `0c. Verify` + path-normalization note, model-identity guidance refined (record an explicit system-prompt model ID rather than only "user fills in"), and a Local-repo-path Pre-Flight field added. Linked from README.

---
## 2026-07-11 — Claude Code / claude-opus-4-8 (consolidated from LocalMind + vert design session)

- **Flaw:** No safe, defined way to propagate *structural* updates (new/changed READMEs, the `flaws/` dir, dedupe rules, etc.) from the package skeleton into already-bootstrapped projects. The only method in practice was copying the skeleton over `.context/`, which overwrites project-owned *data* (session logs, tasks, decisions, user prefs, reviews). Structural updates were hand-carried to each project — tedious, error-prone, and worse with every new project.
- **Symptom:** Throughout the session, every package structural change had to be manually copied into LocalMind; any bulk skeleton copy risked clobbering that project's `.context/` data. Pulling package changes into a parent repo would overwrite data with skeleton stubs.
- **Root cause:** `.context/` never distinguished package-owned *structure* from project-owned *data*, so there was no mechanical, safe sync — every bulk copy was all-or-nothing.
- **Suggested fix:** Make the split explicit with a mechanical **rule** (not a hand-maintained file list): in `context-skeleton/`, a file whose basename is `README.md` or `.gitignore` is structural (sync it); everything else is data (never touch). Ship `SYNC.md` in the skeleton documenting the rule, the two lists, and any non-README structural exceptions. Add a Step 3 sub-step (Path B): reconcile structural files against the skeleton, commit drift as `chore(context): sync structure from package`, never touch data files.
- **Source:** TisoneK/LocalMind (recurring manual sync) + TisoneK/vert design session, 2026-07-11
- **Status:** fixed in this commit — `context-skeleton/SYNC.md` added (rule-first, with the structural/data lists + empty exceptions list); both protocol editions gained the Step 3 structural-sync sub-step, a `SYNC.md` line in the `.context/` structure tree, the 16→17 stub-file count, and Pitfall #33 (don't sync by copying the whole skeleton); skeleton README gained Rule 9 + a file-modes row; package README, QUICKSTART, and `universal-kickoff.md` updated. Detection is by rule so future READMEs sync automatically with no manifest edit.

---
## 2026-07-11 — Claude Code / claude-opus-4-8 (package repo session) — package-clone name inconsistency

- **Flaw:** The docs disagreed on where the package clone lives locally: `QUICKSTART.md` said `~/Code/ai-engineering-protocol`, while `universal-kickoff.md` told agents to clone a sibling named `.context-package`. Neither matched the maintainer's actual convention — name the local clone after the remote repo (`TisoneK/.context` → `.context`). Result: an agent following the kickoff created a second clone (`.context-package`) beside the existing standalone, and the two names drifted.
- **Symptom:** After the vert Session-1 kickoff run, the machine had both `~/Code/ai-engineering-protocol` (standalone) and `~/Code/.context-package` (kickoff-created) — two clones of the same repo under two names, and the standalone fell behind origin because package commits were pushed from the sibling clone.
- **Root cause:** The clone location/name was hardcoded differently in two docs and never aligned to the maintainer's "use the remote repo name" rule.
- **Suggested fix:** Standardize on `.context` (the remote repo name) everywhere: kickoff clones/reuses `../.context` (a sibling), QUICKSTART uses `~/Code/.context`. Add an explicit note that `../.context` (package, one level up) is distinct from a project's in-repo `.context/` memory dir despite the shared basename.
- **Source:** TisoneK/.context — package repo session, 2026-07-11 (raised from vert Session 1)
- **Status:** fixed in this commit — `.context-package` → `.context` across `universal-kickoff.md` and `context-skeleton/SYNC.md`; `QUICKSTART.md` now uses `~/Code/.context`; kickoff carries a package-vs-memory disambiguation note. Standalone clone renamed on disk `ai-engineering-protocol` → `.context`; the redundant `.context-package` clone removed. (Protocol edition filenames `ai-engineering-protocol*.md` are unchanged — only the clone dir name changed.)

---
## 2026-07-13 — Super Z / glm-5.2 + unknown (consolidated from task2sms, Sessions 1–2)

- **Flaw:** The kickoff claimed the package repo (`TisoneK/.context`) is "public — clone directly, no PAT needed." It is private: unauthenticated requests 404 (re-verified from the maintainer's machine, 2026-07-13). Session 1 lost ~3 min to a failed clone; Session 2 (no PAT provided) couldn't reach the 800-line protocol at all and ran on a reconstructed skeleton of it. A follow-up entry correctly reframed part of the root cause as agent-side: the kickoff already said cloud agents "authenticate via a PAT," so the agent should have asked for one at Step 0 before any clone — the stale visibility claim compounded the failure but didn't cause the not-asking.
- **Symptom:** `fatal: could not read Username` on the package clone; Session 2 proceeded without the actual protocol text and framed it as a workaround.
- **Root cause:** Repo visibility changed after the kickoff was written, and the claim was hard-coded prose nothing re-validates; separately, agents waited for clone failures instead of securing credentials up front.
- **Suggested fix:** Correct the claim; flip the Pre-Flight default to private with a "verify, don't trust" note; lead Step 0-C.3 with the authenticated clone; tell cloud agents at Step 0a to ask for PATs before any clone (needed for every push, even to public repos). The inbound kickoff template now instructs verifying visibility at generation time instead of copying a claim.
- **Source:** TisoneK/task2sms — `.context/flaws/log.md`, Sessions 1–2 + second follow-up (2026-07-13)
- **Status:** fixed in package 245ed98 (2026-07-13)

---
## 2026-07-13 — Super Z / glm-5.2 (consolidated from task2sms, Session 2 self-audits)

- **Flaw:** Pitfall #30 ("don't ask permission on the default next step") was misapplied twice, in opposite directions: (1) cited as justification for NOT asking for a missing PAT, leaving 4 finished commits unpushed — but a missing credential is a missing input, not a permission question; (2) violated in a follow-up turn with "would you like me to implement the validator, or just backlog it?" — after the main work looked done, as if follow-up turns weren't bound. The same sessions also shipped a path-traversal vulnerability the agent noticed while writing it (exploit worked first try), an invalid `railway.toml` written from memory (nonexistent `[[volume]]` block, wrong enum casing), and backlogged a confirmed one-line fix.
- **Symptom:** User had to intervene four separate times: provide the PAT unprompted, call out the permission question, catch the security bug, and name the pattern ("the questions you are asking are against context rules").
- **Root cause:** #30 stated the rule but not its boundary (inputs vs permission) nor its temporal scope (follow-up turns); no pitfall covered traversal testing, IaC schema validation, or the backlog-as-deferral anti-pattern.
- **Suggested fix:** Strengthen #30 (follow-up turns bound; "fix or log?" is never genuine ambiguity; inverse boundary stated). Add #34 (missing credential = missing input, ask up front), #35 (traversal test before shipping any user-input→path join, encoded forms included), #36 (validate IaC against its official schema, never from memory), #37 (fix safe one-liners on the spot; the backlog is for design/migration work).
- **Source:** TisoneK/task2sms — `.context/flaws/log.md`, Session 1 follow-up + Session 2 self-audit (2026-07-13)
- **Status:** fixed in package 513de7c (2026-07-13)

---
## 2026-07-13 — Super Z / glm-5.2 (consolidated from task2sms, Session 2)

- **Flaw:** The protocol is sweep-shaped (discover → review → fix); a feature-request Target ("Add Railway hosting support") has nothing to review — it has decisions to design and code to build. The agent had to reinterpret the phases ad hoc.
- **Symptom:** The session worked, but as an improvisation the protocol neither prescribed nor could hold the agent to — design decisions weren't systematically captured as ADRs, and scope boundaries were the agent's guess.
- **Root cause:** No feature mode: Phase 2 assumed "review," Phase 3 assumed "fix findings."
- **Suggested fix:** A `roles/feature-engineer.md` overlay making feature sessions first-class — Phase 2 = design (ADRs in `plans/decisions.md` before code, one-ADR minimum), Phase 3 = implement (all quality gates binding), Step 13 = feature report with an explicit verified / NOT-verified split, plus scope guards (touched-code fixes yes, general sweep no).
- **Source:** TisoneK/task2sms — `.context/flaws/log.md`, Session 2 (2026-07-13)
- **Status:** fixed in package 33cfd8d (2026-07-13)

---
## 2026-07-13 — maintainer decision (task2sms back-port triage)

- **Note (not a flaw):** Two task2sms Session-1 flaws were deliberately NOT back-ported: the pre-provisioned sandbox venv (`/home/z/.venv`, `pip3`-not-`pip`) and the sandbox scaffold `.env` leaking `DATABASE_URL` into the project's process. Maintainer ruling: system-specific flows don't belong in the universal protocol — they are exactly what each project's `.context/system/environments.md` and `inefficiencies/log.md` exist to capture, and the protocol already binds agents to read both before guessing (Step 8). The agent identifies and learns these per environment; the package stays universal.
- **Source:** package maintainer, back-port session 2026-07-13
- **Status:** closed by design — no package change

---
## 2026-07-14 — local agent (consolidated from scrapamoja, Session 6 attempt)

- **Flaw:** The inbound kickoff's local entry step — `[ -d ../.context ] && git -C ../.context pull --ff-only || git clone ... ../.context` — sent a local agent into an endless sync loop, re-cloning a package that was already on disk and synced.
- **Symptom:** The agent kept trying to clone `../.context` every attempt, despite the package sitting fully synced beside the project (as `../context`).
- **Root cause:** Two independent bugs multiplying. (1) Shell semantics: `A && B || C` runs C when **B** fails, not only when A is false — so a failed *pull* (auth, network, divergence) triggers a *clone into an existing directory*, which is fatal, which gets retried forever. (2) Identity by name: the package was recognized only as the hardcoded path `../.context`, but the maintainer's clone is `../context` — renamed because dot-directories are invisible to `ls` and IDE workspace pickers (the same invisibility that caused friction on day one). The name-based check missed the real clone and manufactured a duplicate hidden one.
- **Suggested fix:** Identify the package clone by **remote URL** among sibling candidates (`../context` canonical, `../.context` legacy), never by directory name. A failed pull is not a missing package — continue with the on-disk copy and note it. Never clone when a clone exists: one find → one decision → move on. Re-standardize the canonical clone dir to `../context` (reverses the c0d2597 name-matching decision: matching the remote name `.context` made the dir invisible and collided with the in-repo `.context/` memory dir; `../context` vs `./.context` are now distinct by design, which also simplifies the "two names" warning the docs carried everywhere).
- **Source:** TisoneK/scrapamoja — local session following the cloud-generated `.context/kickoff.md`, 2026-07-14
- **Status:** fixed in package 3742f2f (2026-07-14) — both kickoffs carry the detection loop; editions' Binding Rules card updated; scrapamoja's own kickoff.md regenerated with the fixed steps

---
## 2026-07-14 — Claude Code / claude-fable-5 (package repo session) — maintainer session reached into a project's memory

- **Flaw:** After correctly fixing the endless re-clone loop in the package (3742f2f), the package-maintainer session went on to edit and push `scrapamoja/.context/kickoff.md` directly — another project's memory, which had its own active agent running sessions. The push was rejected mid-flight because that agent had already regenerated the kickoff from the fixed template (relayed by the user); the maintainer session then still added a small consistency commit (1798261) on top, without logging a session entry in that project's `agents/sessions.md`.
- **Symptom:** Rejected push (the one-agent-per-repo collision, live); duplicate work (two agents regenerating the same file); an unlogged commit in a project's memory; user had to point out the scope error: "what we were fixing was context repo not scrapamoja."
- **Root cause:** No stated boundary for package-maintainer sessions. The two-repo model says learnings about the protocol flow to the package — but not the inverse rule: package fixes flow OUT to projects via each project's own sessions (regeneration/sync), never via the maintainer session pushing into project repos. The maintainer conflated "I know the fix" with "I should apply it everywhere."
- **Suggested fix:** State the boundary in the package README's "Working on this repo" section: a package-targeted session's output stops at the package push. Project-side instances of the fix are adopted by each project's own next session (structural files via SYNC; data files like kickoff.md via regeneration), or relayed by the user — the maintainer session does not commit into other projects' `.context/`, especially ones with active agents. The 1798261 commit stands (content correct, history transparent), but the pattern must not repeat.
- **Source:** TisoneK/.context — package repo session, 2026-07-14
- **Status:** fixed in package (this commit) — README boundary added

---
## 2026-07-14 — user observation (cross-agent-type memory contamination)

- **Flaw:** A repo bootstrapped by a cloud agent "infects" subsequent local sessions: after the user pulls the codebase locally, the local agent misbehaves — it picks up the cloud agent's characteristics (PAT dances, token env vars, re-cloning, sandbox commands).
- **Symptom:** Local agent on a cloud-bootstrapped repo follows the cloud edition and cloud environment records as if they were its own instructions.
- **Root cause:** `.context/` memory conflates per-project facts with per-agent-type facts. The bootstrapping agent records ITS edition as `workflows/active.md`'s "Protocol in force," and the inbound kickoff's Step 3 said "read the edition named in workflows/active.md" — so the next agent of the other type reads the first agent's platform binding as the project's binding. Same conflation risk with `environments.md` verified commands (machine-specific) read as universal.
- **Suggested fix:** Make edition choice belong to the agent's TYPE at session start, never to the memory file: `workflows/active.md` template now hard-codes "Protocol: by agent type — naming BOTH editions" with a comment forbidding recording just your own; the inbound kickoff's Step 3 picks by the agent's own type and explicitly distrusts a single-edition record; universal kickoff Step 1b instructs recording both editions keyed by type; Pitfall #43 states the general rule (edition by type, environment blocks only by "Identify by" match, PAT steps never for locals).
- **Source:** user observation across cloud-bootstrap → local-pull sessions, 2026-07-14
- **Status:** fixed in package (this commit)

---
## 2026-09-05 — user report + local Windows verification session (Windows agents deadlock in core sync)

- **Flaw:** The Windows path into the protocol deadlocked. 0.9.0 fixed the git-checkout case (`.gitattributes` eol=lf + CR-stripped manifest parsing), but the verifiers still hashed raw on-disk bytes — so any core reaching disk with CRLF outside a git checkout (hand copies, a CRLF-sourced update, a rollback on a pre-0.9.0 project) failed every file as CORE INTEGRITY FAILURE. The tool's own remediation then failed too: sh `rollback` on such a target re-restored CRLF bytes (verify fails again, forever), and a CRLF `memory/core.lock` poisoned `lock_version`'s comparison so rollback died with "no commit in history has core VERSION". Windows agents hit verify FAIL → rollback FAIL → deadlock and fell back to ad-hoc verification (the pasted session traced exactly this path, manually re-hashing git blobs to prove the content was fine).
- **Symptom:** On Windows with `core.autocrlf=true`: `context-sync verify` (sh and pwsh) failed all 46 core files, exit 3; `context-sync rollback` died finding the locked version. Reproduced pre-fix on Windows 11 / Git Bash / PowerShell 7.6.5 / Windows PowerShell 5.1.
- **Root cause:** The integrity check assumed LF on disk, but `.gitattributes` only guarantees that for git checkouts — nothing enforced it on the cp/Copy-Item paths (update staging, bootstrap, hand copies) and nothing tolerated it at verify time. The sh lock parser assumed the lock file it wrote was the lock file it read.
- **Suggested fix:** (1) Hash CR-stripped content in both verifiers — byte-identical for LF files, so one manifest serves both line-ending worlds and 0.9.0/0.9.1 cores verify either way. (2) Normalize staged copies to LF in sh/ps1 `update` and sh `bootstrap`. (3) Rewrite the restored core to LF after ps1 `rollback`. (4) Strip `\r` in sh `lock_version`. (5) Give the ps1 `update` the `.gitattributes`/`CLAUDE.md` installs 0.9.0 taught only the sh script, on every run including no-ops (the 0.8.x two-run migration). (6) Null/stale-guard `$LASTEXITCODE` in `context-gates.ps1` `Run-One`. During Windows verification the sweep surfaced five more latent defects, fixed in the same release: (7) parameters named `$Args` shadow the PowerShell automatic variable — every `--session/--issue/...` flag was silently lost in `context-collab.ps1`/`context-gates.ps1`; (8) gate logs flowing through the return pipeline made `if (-not (Run-One ...))` compare an array (`-not` on a non-empty array is `$false`) — every gate failure read as a pass in the PowerShell port; the sh port's mirror bug was `run_explicit`/`run_discovered` resetting the caller's `_failed` counter (no locals in sh); (9) a child `.ps1`'s `exit N` does not reliably set `$LASTEXITCODE` on every host and reading it unset trips StrictMode; (10) `Get-ChildItem` on a missing events dir crashed `context-collab-check.ps1` under StrictMode; (11) `cmd_manifest` under Git Bash emitted binary-mode `hash *path` separators, churning the manifest against mac regens.
- **Source:** TisoneK/.context — user report ("Windows agents struggle with context sync and ps scripts since they were written on mac and never verified on a windows machine") + Windows verification session, 2026-09-05
- **Status:** fixed in package — core 0.9.1 (this commit), verified on Windows across sh, PowerShell 7, and Windows PowerShell 5.1

---
## 2026-09-08 — user report (the solo default hides occupancy — every agent believes it's alone)

- **Flaw:** The office-registry metaphor breaks at arrival. The roster (the "who's in" board) is signed only inside Peer Collaboration Mode — a mode an agent enters only after deciding it is *not* solo — and the solo decision keys on `tasks/current.md` being idle, a value that stays "idle" on the shared branch until the first agent's wrap-up commit pushes. The roster is also absent from every session-start read order. So each arriving agent sees an empty board, concludes it's alone, starts a solo protocol, never signs in, never claims a worktree — and the next agent sees the same empty board. N agents run N parallel solo sessions on one repo.
- **Symptom:** Concurrent agents all work "solo" on the same repo; uncommitted changes appear that nobody attributes ("I didn't touch those files"); agents burn their sessions investigating a teammate's anonymous work and drift off-task; the user has to manually remind one agent to emit a note before anyone realizes they were working together all along.
- **Root cause:** Three compounding gaps. (1) Check-in is behind the collaboration door: "Pick a name. Add your row" is step 0 of collaboration mode, so a solo-identifying agent never walks past the registry. (2) The board is not on the read order: neither edition, kickoff, nor AGENTS.md lists `agents/roster.md` at session start. (3) No escalation rule: nothing tells an agent that rows it didn't write (or a non-idle `current.md` pushed live) mean it is NOT solo.
- **Suggested fix:** Make check-in universal: sign the roster in Step 3 of every session, solo included, and push the check-in immediately as its own `chore(context):` commit — presence must be real-time, not wrap-up-time. Add `agents/roster.md` to both editions' read orders, kickoff Step 2, and the AGENTS.md digest. Redefine the solo condition: solo = no declared collab session/issue AND no other live roster rows (and no non-idle `current.md`) — otherwise coordinate (join/declare a session, take a worktree, emit a note) before starting. Clock out at Step 15: clear/complete your row with the closing memory commit; `context-mem check` warns when a session entry is appended while that codename's row still claims an active task. Dirty-tree STOP and "unexpected changes" guidance gain one line: check the roster and collab events before investigating — it may be a teammate's claimed work.
- **Source:** TisoneK/.context — user report (multi-agent occupancy gap), 2026-09-08
- **Status:** fixed in package — core 0.17.0 (this commit)

---
## 2026-09-08 — user report (clock-out is terminal, but sessions resume — the ghost editor)

- **Flaw:** Clock-out (Step 15) is modeled as the end of the session: the agent removes its roster row and logs its `Session N` entry (Step 17) as soon as "the main work looks done." But Pitfall #30 explicitly holds that **the session is not over until the user says it is** — follow-up turns are bound too. So when the manager (supervisor) follows up after wrap-up, the agent resumes *after* it has already left the board. It keeps editing under the identity it just retired, never re-registers, and the board shows it gone. There is no resume / re-check-in path anywhere in either edition, the kickoff, or AGENTS.md.
- **Symptom:** After closeout the manager asks for one more thing; the agent silently re-assumes its old name/codename and keeps committing while its roster row is gone. Other workers see edits landing from someone who is not on the board and can't attribute them — "who's doing the edits?" If the agent instead re-logs at the second wrap-up, a duplicate `Session N` appears in `agents/sessions.md`. Either way the office registry no longer answers "who is in the office now."
- **Root cause:** Clock-out conflates two different events — *finishing a unit of work* (write durable memory) and *leaving the office* (vacate the board) — and fires both at the first wrap-up. Nothing distinguishes a genuine session end from a wrap-up the user is about to reopen, and nothing tells a resumed session to check in again. The identity model (`codename S<N>` = one session) has no rule for "same session, second shift," so agents improvise: re-adopt the retired identity off-board, or open a duplicate entry.
- **Suggested fix:** Separate leaving from wrapping up. (1) Clock out only when the session **truly ends** (the user releases it), not at "main work looks done" — reconcile Step 15 with Pitfall #30. (2) Add a **resume rule**: if you already clocked out (or logged the session) and the user brings more work, you have left the office — **check in again before touching anything**. You are the same session: keep your name and codename `S<N>`, re-add your row, push it as `chore(ledger): <name> (<codename>) checks back in — <task>`. (3) Session log is **one entry per codename `S<N>`** — extend the existing entry across follow-ups; never append a second `Session N`. (4) `ledger-mem check` gains a warn-only audit: two `Session N` entries for one codename in `agents/sessions.md` = a resumed session that re-logged instead of extending. Thread the rule through both editions (check-in + clock-out bullets, Step 15/17, a new pitfall), kickoff, and the AGENTS.md digest.
- **Source:** TisoneK/context-ledger — user report (post-closeout resume gap), 2026-09-08
- **Status:** fixed in package — core 0.19.0 (this commit)

---
## 2026-09-09 — user report from LocalMind S449 (check-in clobbered a live peer's roster row)

- **Flaw:** Two-part roster failure during a peer's live session. (1) On check-in the arriving agent (Otto, S449) did not create its own identity — it found one row on the board (Juno, S448, checked back in) and **answered to the peer's name**, so its work would have been attributed to S448. (2) When corrected, it fixed its row with a replace-style edit whose `old_string`/`new_string` pair spanned the table body *containing Juno's row* — the "correction" swapped the block and **silently deleted the live peer from the board**, then committed and pushed it without a diff review (commit said "Otto checks in" while the change did "Juno checks out"). Rooted in LocalMind's flaw log (86eeaef6); restored in 8353a669.
- **Symptom:** `roster.md` went from 2 live rows (Juno + template) to 1 (Otto) in one commit; a live peer's check-in vanished the moment the next agent registered; the session log would have attributed S449's work to S448.
- **Root cause:** The agent treated the roster as a document it was editing — text to be rewritten — instead of a live shared board where each peer row is a colleague's check-in. Both mistakes share one mechanism: acting on the board as if its only occupant were the agent itself. The protocol's check-in rule says "add or update your row" but never states the edit discipline that makes that safe on a shared board, and nothing requires a diff review before pushing a memory commit.
- **Suggested fix:** Make the additivity explicit in both editions, kickoff, and the AGENTS.md digest: **roster edits are additive — your row only.** Never let an edit's `old_string` span, include, or sit adjacent to a peer's row in a way its replacement could remove it; the Edit tool replaces blocks, so anchoring on the table body erases whoever is on it. After any roster edit the diff must show exactly your own row changed (`+1` on check-in) — review `git diff` before committing, on this file especially.
- **Source:** TisoneK/context-ledger — user report of LocalMind S449 check-in (flaw 86eeaef6), 2026-09-09
- **Status:** fixed in package — core 0.20.0 (this commit)

---
## 2026-09-09 — user report (same model ≠ same agent — check-in adopted a peer's identity)

- **Flaw:** On sync start, an agent inferred "Zola (S455) is ME" because her roster row's model-ID string matched its own system prompt's model name — then moved to treat the peer's dirty main checkout as "my own uncommitted closeout." Doubly wrong: the `cf02f3d0-…` UUID it matched on is the ZCode harness marker shared by every ZCode session (it appears in the S450/S452 sessions.md entries under glm-5.3-flash), and the model suffix `qwen3.8-flash` also matches Nia's row (S454). The misread almost converted a peer's unexplained uncommitted work into "mine, safe to fold into my closeout" — exactly the state Pitfall #20 forbids discarding.
- **Symptom:** An agent claims a live peer's roster row as its own at check-in and starts reasoning about the peer's in-flight state (dirty tree, uncommitted changes) as if it were its own session's leftover.
- **Root cause:** Identity inference from runtime fingerprints. Model IDs, version suffixes, and harness/session UUIDs are fingerprints shared by *every* session running that model or harness — they cannot distinguish two honest peers, and a fresh context can never prove it authored a past entry. Nothing in the protocol said this: the check-in rule said "add or update your row" without stating that an existing matching row is a colleague's, so an agent with no in-context continuity filled the gap with a string match.
- **Suggested fix:** State it in both editions (check-in bullet + Pitfall #45), the kickoff, the AGENTS.md digest, the collaboration README, and the roster template/schema notes: **claim an identity; never infer one.** You are a new arrival until you register — pick a fresh name and codename `S<NNN>` and write your own row. "That row is mine" is justified only by continuity inside your own live context (the re-check-in rule) or the user's word — never by a model/harness-string match. Duplicate model values on the board are normal and expected.
- **Source:** user report of a sync-start session inferring "Zola (S455) is ME" from a model-ID match, 2026-09-09
- **Status:** fixed in package — core 0.21.0 (this commit)

---
## 2026-09-09 — user report (worktrees are created forever, removed never — the abandoned checkouts)

- **Flaw:** Collaboration agents set up the workspace topology exactly as prescribed (product worktree `../<project>-<agent-id>` + branch `collab/<session-id>/<agent-id>`, often the coordination worktree too) and never tear it down at closeout. The protocol teaches creation in five places (check-in/mode bullets in both editions, the collaboration README topology, the kickoff, the AGENTS.md digest) and removal in zero: not Step 15 (clock out), not the EXIT checklists, not the collaboration README.
- **Symptom:** Worktree directories accumulate next to the repo — one per agent per session; `git worktree list` shows stale registrations for directories already deleted by hand; the next session meets "unexpected working-tree changes" and locked paths that belong to nobody, and has to investigate abandoned checkouts before it can trust the tree.
- **Root cause:** The lifecycle was written arrival-heavy. The protocol directs the agent at every point of entry — which worktree to create, which branch to cut it from — but stops at the exit: clock-out and the EXIT checklists cover the roster row, `tasks/current.md`, the logs, and the PAT, but never the rented workspace. What the exit checklist does not list does not happen (the same mechanism Pitfall #26 names for the checklist itself).
- **Suggested fix:** Teach teardown where creation is taught. (1) Both editions: a teardown bullet in the collaboration Isolation guidance, a Step 15 clock-out sentence, and a new EXIT/end-of-session-gates checkbox — after the final `release` and integration, remove your product worktree (from a clean tree; unexplained changes stop you, per Pitfall #20) and delete your product branch (`git branch -d` refuses an unmerged branch; `git push origin --delete` if pushed); `git worktree list` must be clean of your rows. (2) The coordination branch is the deliberate exception: it is the session's event trail — later agents fetch it to continue the session — so it stays; the coordination *worktree* may be removed by the last agent out (re-added in one command next session). (3) A teardown paragraph in the collaboration README's Required workspace topology; the kickoff and AGENTS.md digest gain the short form.
- **Source:** user report (agents not deleting their worktrees after closeout), 2026-09-09
- **Status:** fixed in package — core 0.21.0 (this commit)

## 2026-09-10 — maintainer find (PowerShell port never closed claims by event ID — bare `-or` between command calls)

- **Flaw:** `ledger-collab-check.ps1`'s `Claim-Closed` read `if (Referenced-By-Type $Id 'release' -or Referenced-By-Type $Id 'handoff')`. In PowerShell, a bare `-or` between two command calls inside an `if()` does not evaluate as two boolean command results, so the event-ID closure path silently never matched on Windows — only the path-overlap fallback (shared session+issue + paths) ever closed a claim there. The sh port's `||` was always correct, so the two platforms disagreed on the same trail.
- **Symptom:** On Windows, a release/handoff that cited a claim's event ID still left the claim "active"; `check` failed with "not released or handed off" on trails the sh tool passed.
- **Root cause:** PowerShell expression-mode parsing of command calls around `-or`; every other call site in the port parenthesizes its calls or uses `-not (...)`, this one did not.
- **Suggested fix:** Split into named booleans (`$released = ...`; `$handedOff = ...`; `if ($released -or $handedOff)`). Rule of thumb for the ports: command calls participating in `-and`/`-or` go in parentheses or named variables.
- **Source:** maintainer session, runtime verification of the JSON event work, 2026-09-10
- **Status:** fixed in package — core 0.22.0 (this commit)

## 2026-09-10 — two maintainer sessions, one checkout, zero coordination (the package repo has no office)

- **Flaw:** Two agent sessions ran concurrently against the package repo itself — the protocol's own home — with no coordination surface to discover each other on: no `.context_ledger/` is vendored here, so no roster, no claims, no event trail, no worktree isolation. Each found the peer only by stumbling over uncommitted files it never authored, mid-release, on the same shared release files (VERSION, CHANGELOG.md, MANIFEST.sha256). One session, finding the peer's half-finished tool edits, made its own manifest coherent by stashing them and popping them back — careful and reversible, but the protocol's own rules treat a peer's dirty checkout as a stop-and-coordinate signal, not an obstacle to engineer around. Both sessions noticed the peer mid-flight; neither stopped.
- **Symptom:** Rival manifest regens racing on one tree; a regen that "verifies" a tree containing a peer's unfinished work; two MINOR features both bumping VERSION; a verify that passes or fails depending on which half-finished state was on disk when it ran; and a workaround that touched a peer's in-flight files because the setup left it as the only way out.
- **Root cause:** Upstream of both agents — two workstreams launched on the same checkout simultaneously with no isolation or sequencing between them; that call sits with the supervisor. But the protocol made it easy to miss: its home repo doesn't bootstrap itself, so the one repo where concurrent maintainer sessions are most likely has none of the machinery it mandates everywhere else. Secondary: VERSION/CHANGELOG/MANIFEST are per-release shared files — concurrent independent features make them write-write hazards by construction.
- **Suggested fix:** (1) A one-line rule in the package README's working-on-this-repo section: one workstream at a time — or worktrees plus the collab ceremony — and the manifest regen belongs to the last session to finish. (2) When a maintainer session finds uncommitted files it did not author, that is a live peer: stop and surface to the supervisor before touching shared release files. (3) Longer term: consider vendoring `.context_ledger/` onto this repo (roster + event trail for package work) so discovery happens on a board, not in git status.
- **Source:** maintainer session (collab-events JSON) + peer maintainer session (backlog closeout), relayed by the supervisor, 2026-09-10
- **Status:** rule added to README (this commit); vendoring the protocol onto its own repo is open for the supervisor
