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

## What is covered (core 1.1.3)

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

**UTF-8 encoding** (`ledger-sync.ps1`, ps1-only) — the office migration
preserves non-ASCII in `history.conf`; the lock writer is byte-identical
to the sh port (core 1.0.2).

**Flaw harvesting** (`ledger-sync harvest`, sh-only command) — a scratch
package clone reaches a sibling project checkout and collects one entry
from each `memory/office/` log plus a root `[core-defect]` override —
the office-era layout (core 1.1.3).

The ps1 half of the suite runs only where a PowerShell engine is on
PATH; elsewhere it is skipped with a notice.

Also exercising the suite's own environment: `ledger-sync verify` now
parse-checks every port (`ParseFile` over `bin/*.ps1`, `sh -n` over the
sh ports) — the positive path runs in every session that verifies its
core; break a port in a scratch core copy and verify exits 3.
