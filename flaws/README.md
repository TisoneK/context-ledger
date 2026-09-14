# Consolidated Flaws (package-level — flows in from projects)

This directory is where workflow-level flaws observed across **all
projects** using this protocol are consolidated. Each project's
`.context_ledger/memory/office/flaws/log.md` is the source of truth for that project; this
directory is where patterns are back-ported so the protocol package
itself can be improved.

## The flow

```
Project session hits a workflow flaw
  → logged in the project's .context_ledger/memory/office/flaws/log.md (Status: open)
  → ledger-sync harvest collects it here (into ../inbox/) — see below
  → protocol/core/roles updated in this package to fix it
  → the project's flaw entry gets a "Fixed in package" line
  → new projects bootstrap from the fixed core
```

## Harvesting (automated collection)

The collection step used to be manual copy-paste from each project. It is
now `ledger-sync harvest`, run from a package clone. It reads `fleet.md`
(the registry of bootstrapped projects), reaches each one read-only (a
sibling clone matched by remote URL, else a shallow clone), and pulls in:

- **`memory/office/flaws/log.md`** entries with `Status: open` — every flaw is
  protocol-level by definition, so all open ones are candidates;
- **`memory/office/inefficiencies/log.md`** entries marked `Upstream: candidate` —
  most inefficiencies are project-local and stay put; this opt-in marks
  the protocol-level ones;
- **`overrides/rules.md`** bullets tagged `[core-defect]` — these are the
  richest signal: a project has already *written the fix* to a core bug
  locally, and it would otherwise stay stranded there (overrides survive
  every core bump). `[project-local]` overrides are never harvested.

Output lands in `../inbox/harvest-<date>.md` for triage; a committed
ledger (`../inbox/.harvested`) hashes each collected entry so re-runs
never re-file the same one. Triage each entry (fix in core, or reject),
then delete the run file — the ledger remembers.

## How to use this directory

- **Reading:** Before improving the protocol, scan this log for patterns.
  If the same flaw appears across multiple projects, it's a high-priority
  fix.
- **Writing:** When back-porting a project flaw, copy the entry here with
  a `Source:` line pointing to the project + session. Don't copy
  one-off flaws that are unlikely to recur — those stay in the project.
- **Fixing:** When you fix a flaw in the protocol (a new pitfall, a
  reworded step, a new template field), note the fix in the entry's
  `Status:` line with the commit SHA. Then the project that reported it
  can update its own entry to "Fixed in package <sha>".

## Format

```
---
## YYYY-MM-DD — <agent> / <model> (consolidated from <project>, Session N)

- **Flaw:** <what in the protocol or .context_ledger/ system didn't work>
- **Symptom:** <what happened to the agent — the observable friction>
- **Root cause:** <why the protocol/.context_ledger/ let this happen>
- **Suggested fix:** <concrete change to the package>
- **Source:** <project repo> — .context_ledger/memory/office/flaws/log.md, Session N
- **Status:** open | fixed in <commit-sha> on <date>
```

## Current open flaws (consolidated from LocalMind)

The 4 flaws below were observed by GitHub Copilot / DeepSeek V4 Flash
Free during LocalMind Session 3 (2026-07-11). They are all about the
protocol not guiding the agent well enough during `.context_ledger/`-only
tasks. All 4 are open — none have been fixed in the protocol yet.
