# Package tests

Maintainer-facing test suite for the protocol package itself — this
directory is **not** vendored into projects (only `core/` travels).

Run it with POSIX sh (Git Bash on Windows, any sh on macOS/Linux):

```sh
sh tests/run-tests.sh
```

Run it before every `core/` release — it exercises both editions (sh and
PowerShell) on scratch projects, so a fix that works in one port but not
the other fails here. Exit 0 = green.

## What is covered (core 2.0.4)

**Windows port health** — 2.0.3 shipped PowerShell ports that no engine
could parse on a stock Windows box, which made `ledger-sync verify` exit
3 there and took every gate down with it. Four assertions now hold:

- **the ports are pure ASCII** — Windows PowerShell 5.1 decodes a
  BOM-less script with the *system codepage*, not UTF-8, so a literal
  em-dash becomes U+201D (a string terminator) for 5.1 while pwsh 7
  parses the same bytes fine. Text needing a non-ASCII character builds
  it from its code point instead ([char]0x2014), which is what keeps the
  ports byte-identical to their sh twins without any encoding risk;
- **every port parses under every engine on PATH**, not just the first
  one found: the `.cmd` launchers target 5.1 on purpose, so a
  pwsh-only-parseable port is a runtime failure waiting to happen;
- **the sh port's encoding guard fires** — a scratch core carrying a
  non-ASCII byte fails `verify` with rc=3 and the encoding message, with
  the tree manifest-clean so only the guard can be responsible;
- **sh and ps1 write the same STATE.md**, byte for byte (the
  `_Regenerated:` timestamp aside). This is what pins the em-dash
  convention: the two ports drifted once already, the ps1 writing a
  hyphen where the sh writes an em-dash in the Core block.

**The gate verdict** (`core/bin/ledger-gates{,.ps1}`) — the headline case
is the flaw back-ported from a fleet project: a POSIX pipeline reports
only its last stage's status, so a gated `failing-cmd | tee out.txt`
used to pass with the tool under test failing.

- a gated failing command piped into a succeeding consumer **must fail
  the gate** on every host — via `pipefail` where the shell supports it,
  via rejection of the unverifiable pipeline where it does not;
- a gated succeeding pipeline still passes where the verdict is
  verifiable, and is rejected (never silently passed) where it is not;
- `||` fallbacks and quoted `|` are never rejected on no-pipefail shells;
- the PowerShell edition rejects pipelines with **two or more external
  stages** (its verdict would be the last native command's exit code)
  and keeps single-native pipelines working (`Tee-Object` tails are
  safe: `$LASTEXITCODE` survives cmdlet stages).

**Log compaction advisory** (`ledger-mem prune`, both ports) — a
resolved entry and a superseded ADR report as archive-eligible, 3+
entries sharing a Problem line report as a roll-up candidate, and the
closed-marker counts **only** from an entry's own Status line: prose
mentions and `<!-- -->` template comments never make an entry eligible
(core 1.1.2).

**One-way-linkage sweep** (`ledger-mem lint --tree`, both ports) —
product leaks report with `file:line`, memory files and clean files
stay out of the report (core 1.1.0).

**Capped backlog queue** (`ledger-mem check`, both ports) — the
`tasks/backlog.md` work queue holds at most `backlog_cap` actionable
rows (default 20, read from `workflows/history.conf`): a backlog at the
cap passes silently, one row past it draws a **warn-only** nudge to
prune into `parking-lot.md` (the check still exits 0 — a full queue is
advisory, never a gate failure), and raising `backlog_cap` in
`history.conf` silences it. The `ledger-history` pre-close checklist
carries the matching "re-seed WORK, not knowledge" rule (core 1.2.0).

**UTF-8 encoding** (`ledger-sync.ps1`, ps1-only) — the office migration
preserves non-ASCII in `history.conf`; the lock writer is byte-identical
to the sh port (core 1.0.2).

**Flaw harvesting** (`ledger-sync harvest`, sh-only command) — a scratch
package clone reaches a sibling project checkout and collects one entry
from each `memory/office/` log plus a root `[core-defect]` override —
the office-era layout (core 1.1.3).

The ps1 half of the suite runs only where a PowerShell engine is on
PATH; elsewhere it is skipped with a notice.

Also exercising the suite's own environment: `ledger-sync verify`
parse-checks every port (`ParseFile` over `bin/*.ps1` under each engine
on PATH, `sh -n` over the sh ports) and fails a ps1 port carrying a
non-ASCII byte (core 2.0.4) — the positive path runs in every session
that verifies its core; break a port in a scratch core copy and verify
exits 3.
