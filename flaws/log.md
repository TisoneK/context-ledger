# Consolidated Flaws Log (package-level)

Workflow-level flaws consolidated from all projects using this protocol.
See `README.md` in this directory for the flow and format.

---
## 2026-07-11 — GitHub Copilot / DeepSeek V4 Flash Free (consolidated from LocalMind, Session 3)

- **Flaw:** The protocol's Step 3 ("Read `.context/`") doesn't emphasize hard enough that reading `workflows/active.md` is a **binding instruction** to load and execute the referenced protocol — not passive documentation.
- **Symptom:** Agent read `workflows/active.md` in its first tool calls, saw that the protocol lives in `TisoneK/.context`, but then jumped straight to editing `.context/` files without fetching or following the protocol. User had to redirect: "Don't you have the workflow?"
- **Root cause:** The protocol describes the workflow file as something to read, not as an instruction to act on. There's no explicit "after reading the workflow, immediately load the protocol it references before any other tool use" rule. An agent can read the workflow passively (as context) rather than actively (as a command).
- **Suggested fix:** Add to Step 3 (or a new pitfall): "Reading `workflows/active.md` is a binding instruction. After reading it, immediately fetch and load the protocol it references before any other tool use. Don't treat it as documentation — it's the instruction set for this session." Consider adding a dedicated "Load the protocol" sub-step between Step 3 (read `.context/`) and Step 4 (install deps).
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 3
- **Status:** open

---
## 2026-07-11 — GitHub Copilot / DeepSeek V4 Flash Free (consolidated from LocalMind, Session 3)

- **Flaw:** The protocol doesn't tell the agent **where the protocol itself lives** when the agent is working on a project (not on the package repo). An agent on a fresh project clone has the project's `.context/` but not the protocol file — it has to fetch it from `TisoneK/.context` on GitHub, and the workflow file says "from the `TisoneK/.context` package" but doesn't say "fetch it from GitHub using these coordinates."
- **Symptom:** Agent tried multiple wrong local paths to find the protocol: VS Code prompts folder, workspace globs (`**/*protocol*`, `**/*.instructions.md`, `**/*.prompt.md`). All returned nothing. 4 failed search tool calls before using `github_repo` to fetch the protocol from `TisoneK/.context`.
- **Root cause:** The workflow file references the package by name ("from the `TisoneK/.context` package") but doesn't give explicit fetch instructions. The protocol's Step 1–3 don't say "if you don't have the protocol file locally, fetch it from the URL in `workflows/active.md`." An agent that hasn't internalized the two-repo model (package vs project) will search locally first.
- **Suggested fix:** Add to `workflows/active.md` template an explicit "Protocol source" field: `github.com/TisoneK/.context/blob/main/ai-engineering-protocol.md` (or the local edition). Add to Step 3: "If the protocol file is not present in the working directory, fetch it from the URL in `workflows/active.md`'s Protocol source field."
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 3
- **Status:** open

---
## 2026-07-11 — GitHub Copilot / DeepSeek V4 Flash Free (consolidated from LocalMind, Session 3)

- **Flaw:** The protocol's execution order (Phase 1 before any editing) is stated as a sequence but not enforced as a **rule**. An agent can treat a small task ("initialize `.context/`") as "too small for the protocol" and skip Phase 1 entirely.
- **Symptom:** Agent registered itself in `ai-models.md`, added its environment to `environments.md`, logged its session in `sessions.md`, updated `workflows/active.md`, and set `tasks/current.md` — all before completing Phase 1 (pull, read docs, discovery). The edits were correct but the sequence violated Steps 2–6. Required a backtrack to re-do discovery properly.
- **Root cause:** The protocol says "execute these steps sequentially" but doesn't explicitly say "regardless of task size" or "even for `.context/`-only tasks." An agent reasoning about efficiency might conclude that a trivial task doesn't need the full Phase 1 setup.
- **Suggested fix:** Add to the protocol's Autonomous Execution Steps preamble: "These steps run in order for every session, regardless of task size. A one-line `.context/` edit still requires Phase 1 (pull, read `.context/`, read docs, discovery, baseline) before any file is modified. Skipping Phase 1 because the task seems small is the most common protocol violation." Add as a Common Pitfall.
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 3
- **Status:** open

---
## 2026-07-11 — GitHub Copilot / DeepSeek V4 Flash Free (consolidated from LocalMind, Session 3)

- **Flaw:** The protocol doesn't explicitly distinguish **two surfaces** (the project vs `.context/`) in a way that forces the agent to declare which one it's working on.
- **Symptom:** Agent mixed `.context/` edits (registering itself, logging its session) with what should have been protocol-governed project work, without distinguishing the two. The `chore(context):` commit prefix exists but wasn't enough to enforce the mental separation.
- **Root cause:** The protocol has one execution flow that covers both surfaces. There's no explicit "I am now working on `.context/`" or "I am now working on the project" declaration step.
- **Suggested fix:** Add a "Two Surfaces" section to the protocol (early, before Phase 1) that defines: (1) The project — product code, normal commit prefixes, friction → `inefficiencies/`. (2) `.context/` — agent memory, `chore(context):` prefix, friction with the system → `flaws/`. State: "Know which surface you're on at all times."
- **Source:** TisoneK/LocalMind — `.context/flaws/log.md`, Session 3
- **Status:** open

---
## 2026-07-11 — DeepSeek V4 Flash Free (cold start, 2nd instance — consolidated from LocalMind)

- **Flaw:** No discovery mechanism. The protocol assumes the agent opens `.context/` first, but nothing at the repo root signals that `.context/` exists or that a protocol should be followed. A fresh agent with no prior session context treats the repo as a product to run, not a project to work on under protocol.
- **Symptom:** In a cold-start session (no uploaded protocol file, no prior chat context), the agent received "Start context workflow" and interpreted it as "start LocalMind's Context Builder feature" (the app's runtime context system). It explored the codebase, started the backend server, checked the health endpoint, and reported "The context workflow is now running" — referring to LocalMind's engine, not the agent-memory protocol. At no point did it read `.context/`, open `workflows/active.md`, fetch the protocol, set `tasks/current.md`, or log a session entry.
- **Root cause:** Every prior flaw fix (binding-workflow rule, protocol source field, session lifecycle, no-task-too-small) assumes the agent has already opened `.context/` and is reading `workflows/active.md`. But there's nothing at the repo root that tells a fresh agent "read `.context/` first." The `.context/` directory doesn't appear in the code — it's metadata, not code — so code exploration never surfaces it. A naming collision made it worse: "context" is overloaded in LocalMind (the app has a "Context Builder" feature; the agent memory is `.context/`), so grepping for "context" surfaces the product feature, not the protocol.
- **Suggested fix:** Add a discovery file at the repo root that agents auto-load. The emerging industry convention is `AGENTS.md` (tool-agnostic) plus a `CLAUDE.md` symlink/copy (Claude-specific discovery). Content: "This repo uses the `.context/` agent-memory protocol. Before doing any work: 1. Read `.context/workflows/active.md` — it names the protocol edition to follow. 2. Fetch that protocol from the URL in its 'Protocol source' field. 3. Follow the protocol's Phase 1 before editing any file." Add `AGENTS.md` to `context-skeleton/` so new projects get it automatically. Note: this is not a silver bullet — agents must still choose to read it — but it's strictly better than the current state (zero discovery mechanism). Layered defense: (1) `AGENTS.md` at root, (2) `CLAUDE.md` at root, (3) user explicitly saying "follow the protocol" at session start.
- **Source:** TisoneK/LocalMind — cold-start session, 2nd instance of DeepSeek V4 Flash Free missing the protocol (1st instance was Session 3, which found `.context/` but didn't follow it). This 2nd instance is the cleaner data point — no prior context to bias it.
- **Status:** open — fix deferred until after a cold-start test of GLM-5.2 to confirm the pattern across models (if GLM-5.2 also misses it, it's a protocol gap; if GLM-5.2 finds it, it's a model-specific observation).
- **Fixed in package:** 2026-07-14, core 0.2.0 — bootstrap now generates a root `AGENTS.md` from `core/templates/AGENTS.md` (the schema's "translation layer" tier 1): zones, the never-write-core rule, entry point `.context/kickoff.md`, the condensed binding rules; optionally copied as `CLAUDE.md` / `.github/copilot-instructions.md`. The cold-start test remains worth running, but new bootstraps no longer ship with zero discovery mechanism.

---
## 2026-07-13 — Claude Code / claude-fable-5 (package repo session) — agent asked permission to commit/push instead of doing it

- **Flaw:** After completing two features on the package repo, the agent ended its turn asking "Want me to commit them — and push?" instead of committing each logical change and pushing, leaving two features' worth of work sitting uncommitted in the working tree across multiple turns. The protocol's own exit rule — "If the user has to remind you to commit or push, the protocol failed — log it as a flaw" — fired exactly as written.
- **Symptom:** User had to point out the violation explicitly ("Means you are not following context rules either") before the work was committed and pushed. Session defaults (push to main after each commit, one logical change per commit, no confirmation on default next steps) were all documented in the very files the agent was editing.
- **Root cause:** Two-fold. (1) The session was started with direct feature specs in chat, not through a kickoff — so the agent never formally entered the protocol and its harness-level conservative git defaults ("commit/push only when asked") silently won over the protocol's defaults. (2) The kickoff's "the agent never pushes to the package repo unless explicitly asked" rule creates ambiguity for sessions whose *target is the package itself*: the agent can read it as covering exactly this case, when it actually guards project sessions against stray package pushes.
- **Suggested fix:** State the surface rule explicitly in the package README and/or kickoff: when the package repo is the session's target, the package IS the project repo for that session — normal session defaults apply (commit per logical change, push after each commit, no confirmation prompts). The "never push to the package" rule applies only to sessions targeting some other project. Also note that direct-task sessions on the package (no kickoff handed over) still inherit the protocol's session defaults — the package repo's own docs are the standing workflow.
- **Source:** TisoneK/.context — package repo session, 2026-07-13 (inbound-kickoff + per-repo-privacy feature work)
- **Status:** open
- **Fixed in package:** 2026-07-13, same session — README gained a "Working on this repo" section stating that package-as-target sessions inherit the full session defaults (commit per logical change, push after each, no permission prompts) and that the "never push to the package" rule guards only sessions targeting other projects.
