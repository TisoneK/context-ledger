# Context Ledger

**Persistent, repository-native memory for AI coding agents — and the
protocol that keeps it honest.**

## The gap in the stack

A codebase accumulates history tools. Git remembers the **code**
history. The issue tracker remembers the **ticket** history. The docs
remember the **knowledge** history. Nothing remembers the **operational
context between agent sessions**: what was investigated, what was
decided and *why*, what is deliberately unfinished, which approach
already failed, what the last agent learned about the user or the
machine.

So the next agent — a different model, a different machine, a fresh
context window — starts as a stranger. You become the message bus
between your own sessions, re-explaining state the project already
knows.

## The fix

Context Ledger makes the repository itself the memory. Every project
carries a `.context_ledger/` directory with two zones — a versioned
**core** (the protocol agents follow) and a living **memory** (what the
agents actually did) — committed to git, updated in the same pushes as
the code. One rule runs every session:

> **Start by reading the ledger. Finish by updating it.**

Different agent. Different model. Different machine. Same project
memory.

## A session, concretely

```text
SESSION 1 — Tuesday, model A
  reads .context_ledger/kickoff.md → sessions, tasks, decisions, logs
  investigates a timezone bug; fixes half of it
  a schema trade-off forces a decision → recorded as an ADR
  clock-out: session logged, two open tasks queued, one test-harness
  trap noted, everything committed and pushed

SESSION 2 — Wednesday, model B, different laptop
  reads the same files → knows where the work stands in a minute
  skips the trap model A already mapped, continues the other half
  never asks the user to re-explain anything
```

## What it is not

This is not another chat-history summarizer or a vector store bolted
onto an agent. The difference is structural:

- **Memory is plain markdown in git.** Human-readable session logs,
  ADRs, a task queue, friction logs — diffable in a pull request,
  versioned with the code, reviewable with the same tools that review
  the code. No server, no embeddings, nothing to run.
- **Memory has discipline.** Agents don't just append notes. Every
  session checks in at a roster (who's in the office *now*), claims
  scope before editing, runs lifecycle gates before committing, and
  clocks out — so the ledger stays current instead of rotting into
  stale documentation. Concurrent agents coordinate through immutable
  event records, like coworkers, not like writers racing over one file.
- **The protocol travels inside the project.** It is *vendored* at
  bootstrap — a fresh clone carries the complete operating manual for
  its agents. After bootstrap, no session needs a GitHub account, a
  clone of anything, or the network: there is no runtime dependency to
  break.
- **It remembers failure, not just success.** Two friction logs keep
  what went wrong — project traps agents hit, and flaws in the
  protocol itself. The second flows back to the package and ships as
  new releases: the protocol was shaped by the agents that used it.

## What the ledger remembers

```text
memory/
├── office/                  # the live office — everything the current
│   │                        #   set of sessions produces
│   ├── agents/sessions.md   # who did what, which model, which machine
│   ├── agents/roster.md     # the board by the door: who's working now
│   ├── tasks/               # current.md (in flight) + backlog.md (queue)
│   ├── plans/decisions.md   # ADRs — why things are the way they are
│   ├── flaws/               # friction with the protocol → flows upstream
│   ├── inefficiencies/      # friction with the project → traps to avoid
│   ├── sessions/            # per-session notes + compressed summary
│   └── reviews/             # each session's report
├── system/                  # machines + agent/model pairs, verified commands
├── user/                    # who the user is and how they like things done
├── workflows/               # standing session parameters + gate registry
└── collaboration/           # immutable peer-coordination events (opt-in)
```

Offices have a capacity: when one fills up it is frozen verbatim into
`history/` with a permanent accomplishments record, and a fresh office
opens — memory that bounds itself instead of growing to unreadable.

## The two zones

```text
.context_ledger/
├── kickoff.md      # THE FRONT DOOR — every session starts here
├── core/           # the protocol, vendored — READ-ONLY, version-stamped,
│   │               #   checksummed; replaced only as a whole tree
│   ├── rules/      # two editions: local IDE agents · cloud/sandbox agents
│   ├── schemas/    # the single source of truth on every memory file format
│   ├── roles/      # mission overlays (reviewer, security-auditor, docs-agent…)
│   └── bin/        # ledger-sync · ledger-collab · ledger-gates ·
│                   #   ledger-mem · ledger-history (sh + PowerShell ports)
└── memory/         # the project's living memory — project-owned, writable,
                    #   never touched by protocol updates
```

## Getting started

The tools are pure POSIX sh with PowerShell ports — no installation,
no dependencies, no package manager. On Windows, every `.ps1` has a
`.cmd` launcher that needs no execution-policy setup.

```bash
git clone https://github.com/TisoneK/context-ledger.git
sh context-ledger/core/bin/ledger-sync bootstrap path/to/your-project
# in that project: git add .context_ledger AGENTS.md, commit, push
```

Or skip the CLI: hand [`universal-kickoff.md`](universal-kickoff.md) to
any agent and say "bootstrap this project" — it runs the same steps and
fills in the first memory. From then on, every session on that project
starts with one sentence to the agent:

> Read `.context_ledger/kickoff.md` and follow it.

It has run in production on the maintainer's fleet — several real
projects plus this repo itself, which uses its own protocol to develop
its own protocol.

## Where to go next

| Read | What it is |
|---|---|
| [`QUICKSTART.md`](QUICKSTART.md) | The mental model + bootstrap walkthrough — start here if the picture above clicked. |
| [`core/rules/`](core/rules/) | The protocol editions — the full session lifecycle. |
| [`core/schemas/ledger-schema.md`](core/schemas/ledger-schema.md) | The format of every memory file: zones, write modes, fact scopes. |
| [`universal-kickoff.md`](universal-kickoff.md) | The one-time bootloader, for a project's first-ever session. |
| [`designs/`](designs/) | Design documents behind the big moves (office architecture, collaboration events, session grouping). |
| [`MVP.md`](MVP.md) | Public-release plan + feature roadmap — the single home for future ideas. |
| [`MIGRATION.md`](MIGRATION.md) | Moving pre-0.2.0 projects to the two-zone layout — one commit, zero data loss. |
| [`examples/localmind-review.md`](examples/localmind-review.md) | A real session report produced under the protocol. |
| [`flaws/`](flaws/) | Consolidated protocol friction, back-ported from every project — the source of improvements. |
| [`core/CHANGELOG.md`](core/CHANGELOG.md) | Release history of the protocol itself, with migration notes. |

## Working on this repo (the package as the session's target)

When a session's task is to change the **package itself** — a new
feature, a protocol fix, a flaw back-port — the package IS that
session's project repo, and the normal session defaults apply in full:
one logical change per commit, push after each commit, no confirmation
prompts on default next steps. This applies even when the session was
started with a direct task in chat rather than a kickoff file. Friction
with the protocol found while doing package work goes straight into
[`flaws/log.md`](flaws/log.md).

**Maintainer discipline:** any change under `core/` must regenerate the
manifest in the same commit — `sh core/bin/ledger-sync manifest` — and
pass the package test suite — `sh tests/run-tests.sh` — and
release-worthy changes bump `core/VERSION` + add a `core/CHANGELOG.md`
entry (semver: spec/layout breaks = MAJOR, features = MINOR, wording =
PATCH). **One workstream at a time.** Sessions here share the
self-hosted `.context_ledger/` office (see below): check in, claim, and
coordinate there. If you find uncommitted files you did not author, that
is a live peer — stop and surface to the supervisor instead of working
around them, and leave the manifest regen to the last session to finish.

**Self-hosting: this repo runs its own vendored `.context_ledger/`.**
Sessions here work like any project's — check in on the roster, claim
scope, log the session. The vendored core tracks **releases, not dev
head**: when a release commit lands, the releasing session syncs the
ledger as its closing step — `sh .context_ledger/core/bin/ledger-sync
update core` (the source is this repo's own `core/`) — verifies, and
commits as `chore(ledger): self-host core <version>`. Between releases
the board deliberately runs the last release; dev head isn't protocol
until it ships. MAJOR bumps still require the user's go-ahead
(`update --major`).

**The boundary: a package session's output stops at the package push.**
Fixes reach projects through **their own** next sessions —
`ledger-sync update` for core, regeneration for generated files — or
through the user relaying it. The maintainer session never commits into
another project's `.context_ledger/`, however obvious the fix: those
repos have their own agents, their own session logs, and their own locks.
Fix the source; let the instances pull.
