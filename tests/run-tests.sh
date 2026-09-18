#!/bin/sh
# Package test suite for the context-ledger protocol (maintainers; this
# directory is NOT vendored into projects).
#
# Run from anywhere:  sh tests/run-tests.sh
#
# What it covers (core 1.0.3): the gate verdict (shipped 1.0.1, completed
# 1.0.3) and the UTF-8 encoding regressions (shipped 1.0.2). The gate half:
# a POSIX pipeline reports only its last stage's status, so a gated
# `failing-cmd | tee out.txt` used to pass with the tool under test failing
# (flaw back-ported from a fleet project). Core 1.0.3 closes the second half
# of the same flaw on the PowerShell edition: Run-One ran the gated command
# inline, so a command that PRINTS to stdout and exits nonzero returned
# @(lines..., $false) -- -not on a non-empty array never registered the
# failure, and the gate printed FAILED (N) and then GATE PASSED with rc=0.
# The suite asserts, on scratch projects, against BOTH editions:
#   - a gated failing command piped into a succeeding consumer fails the gate
#     (via pipefail where the shell supports it, via rejection where it does
#     not -- either way the gate fails);
#   - a gated command that prints a line and exits nonzero fails the gate,
#     its output stays visible, and the verdict line (FAILED (N)) is asserted
#     -- never the wrapper rc alone;
#   - a gated succeeding pipeline still passes where the verdict is verifiable;
#   - `||` fallbacks and quoted `|` are not rejected on no-pipefail shells;
#   - the PowerShell edition rejects pipelines with two or more external
#     stages (its verdict would be the last native command's exit code) and
#     keeps passing/failing single-native pipelines correctly.
# The ps1 half runs only where a PowerShell engine is on PATH; elsewhere it is
# skipped with a notice.
#
# Exit: 0 all green, 1 any failure.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PKG_DIR=$(dirname -- "$SCRIPT_DIR")
CORE=$PKG_DIR/core
PASS=0; FAIL=0

say() { printf '%s\n' "$*"; }
ok()  { PASS=$((PASS + 1)); say "  ok: $1"; }
bad() { FAIL=$((FAIL + 1)); say "  FAIL: $1"; }

# A scratch project: a git repo with a vendored copy of core/bin, so the gate
# tools resolve their own project dir to the scratch, plus a gates.conf. The
# universal pre-commit check needs one commit so `git diff --cached` is clean.
make_scratch() { # $1 = dir
  rm -rf "$1"
  mkdir -p "$1/.context_ledger/core" "$1/.context_ledger/memory/workflows"
  cp -R "$CORE/bin" "$1/.context_ledger/core/bin"
  : > "$1/.context_ledger/memory/workflows/gates.conf"
  git -C "$1" -c init.defaultBranch=main init -q 2>/dev/null || git -C "$1" init -q
  git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

set_conf() { # $1 = scratch dir, $2 = one conf line
  printf '%s\n' "$2" > "$1/.context_ledger/memory/workflows/gates.conf"
}

# expect_rc <want:fail|pass> <name> <scratch> <gate invocation...>
expect_rc() {
  _want=$1; _name=$2; _scratch=$3; shift 3
  "$@" > "$_scratch/.test-out.log" 2>&1
  _rc=$?
  case "$_want:$_rc" in
    pass:0)        ok "$_name" ;;
    fail:*)        ok "$_name (rc=$_rc)" ;;
    *) bad "$_name -- rc=$_rc, want $_want"; tail -n 5 "$_scratch/.test-out.log" ;;
  esac
}

say "package tests -- core $(head -n1 "$CORE/VERSION" | tr -d '[:space:]')"

# ---- sh edition -------------------------------------------------------------
SH_SCRATCH=${TMPDIR:-/tmp}/ledger-test-sh
make_scratch "$SH_SCRATCH"
SH_GATE="sh $SH_SCRATCH/.context_ledger/core/bin/ledger-gates run pre-commit"

# The headline case: a gated failing tool piped into a succeeding consumer
# must fail the gate. Passes via pipefail where available, via rejection
# where not -- either way, no silent pass.
set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 3' | tee out.txt"
expect_rc fail "sh: gated 'failing-cmd | tee' fails the gate" "$SH_SCRATCH" $SH_GATE

if sh -c 'set -o pipefail' >/dev/null 2>&1 || bash -c 'set -o pipefail' >/dev/null 2>&1; then
  PIPEFAIL_OK=1
  set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 0' | tee out.txt"
  expect_rc pass "sh: gated 'ok-cmd | tee' passes (pipefail host)" "$SH_SCRATCH" $SH_GATE
else
  PIPEFAIL_OK=0
  set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 0' | tee out.txt"
  expect_rc fail "sh: gated 'ok-cmd | tee' is rejected (no pipefail host)" "$SH_SCRATCH" $SH_GATE
fi

set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 3'"
expect_rc fail "sh: plain failing command fails" "$SH_SCRATCH" $SH_GATE

set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 0'"
expect_rc pass "sh: plain succeeding command passes" "$SH_SCRATCH" $SH_GATE

# The chatty-failure half of the gate-teeth flaw: stdout must never change
# the verdict, the tool's output must stay visible, and the per-command
# verdict line must be asserted -- never the wrapper rc alone.
set_conf "$SH_SCRATCH" "pre-commit|sh -c 'echo gate-teeth-probe; exit 3'"
expect_rc fail "sh: chatty failing command fails the gate" "$SH_SCRATCH" $SH_GATE
if grep -q "gate-teeth-probe" "$SH_SCRATCH/.test-out.log"; then
  ok "sh: chatty failing command's output stays visible"
else
  bad "sh: chatty failing command's output was swallowed"
fi
if grep -q "FAILED (3):" "$SH_SCRATCH/.test-out.log"; then
  ok "sh: verdict line asserted (FAILED (3))"
else
  bad "sh: no FAILED verdict line for the chatty failure"
fi

# `||` is deliberate fallback semantics -- never rejected, on any shell.
set_conf "$SH_SCRATCH" "pre-commit|sh -c 'exit 3' || sh -c 'exit 0'"
expect_rc pass "sh: '||' fallback is not rejected" "$SH_SCRATCH" $SH_GATE

# A quoted `|` is argument text, not a pipeline -- never rejected.
printf 'a|b\n' > "$SH_SCRATCH/fixture.txt"
set_conf "$SH_SCRATCH" "pre-commit|grep -q 'a|b' fixture.txt"
expect_rc pass "sh: quoted '|' is not rejected" "$SH_SCRATCH" $SH_GATE

# ---- PowerShell edition -----------------------------------------------------
PS_BIN=$(command -v powershell || command -v pwsh) || PS_BIN=""
if [ -z "$PS_BIN" ]; then
  say "  skip: PowerShell edition (no powershell/pwsh on PATH)"
else
  PS_SCRATCH=${TMPDIR:-/tmp}/ledger-test-ps
  make_scratch "$PS_SCRATCH"
  GATE_PS=$PS_SCRATCH/.context_ledger/core/bin/ledger-gates.ps1
  if command -v cygpath >/dev/null 2>&1; then GATE_PS_W=$(cygpath -w "$GATE_PS"); else GATE_PS_W=$GATE_PS; fi
  ps_gate() { "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$GATE_PS_W" run pre-commit; }

  # The case the pre-1.0.1 gate silently passed: two external stages, the
  # tail succeeding. The verdict would be the tail's -- so it is rejected.
  set_conf "$PS_SCRATCH" "pre-commit|cmd /c exit 3 | cmd /c exit 0"
  expect_rc fail "ps: pipeline with two external stages is rejected" "$PS_SCRATCH" ps_gate

  # The literal flaw shape on PowerShell: tee resolves to the Tee-Object
  # cmdlet, one external stage -- runs, and the failing tool's exit code
  # surfaces through \$LASTEXITCODE.
  set_conf "$PS_SCRATCH" "pre-commit|cmd /c exit 3 | Tee-Object out.txt"
  expect_rc fail "ps: gated 'failing-cmd | Tee-Object' fails the gate" "$PS_SCRATCH" ps_gate

  set_conf "$PS_SCRATCH" "pre-commit|cmd /c exit 0 | Tee-Object out.txt"
  expect_rc pass "ps: gated 'ok-cmd | Tee-Object' passes" "$PS_SCRATCH" ps_gate

  set_conf "$PS_SCRATCH" "pre-commit|cmd /c exit 3"
  expect_rc fail "ps: plain failing command fails" "$PS_SCRATCH" ps_gate

  set_conf "$PS_SCRATCH" "pre-commit|cmd /c exit 0"
  expect_rc pass "ps: plain succeeding command passes" "$PS_SCRATCH" ps_gate

  # The headline 1.0.3 regression: a gated command that prints a line and
  # exits nonzero used to return @(lines..., $false) from Run-One -- -not on
  # a non-empty array never registered the failure, so the gate printed
  # FAILED (1) and then GATE PASSED with rc=0. Assert the verdict line AND
  # the gate-level failure, with the child's output visible.
  set_conf "$PS_SCRATCH" 'pre-commit|cmd /c "echo gate-teeth-probe & exit /b 1"'
  expect_rc fail "ps: chatty failing command fails the gate" "$PS_SCRATCH" ps_gate
  if grep -q "gate-teeth-probe" "$PS_SCRATCH/.test-out.log"; then
    ok "ps: chatty failing command's output is re-emitted, not swallowed"
  else
    bad "ps: chatty failing command's output was swallowed"
  fi
  if grep -q "FAILED (1):" "$PS_SCRATCH/.test-out.log" \
     && grep -q "pre-commit gate failed" "$PS_SCRATCH/.test-out.log"; then
    ok "ps: verdict lines asserted (FAILED (1) + gate failed)"
  else
    bad "ps: no FAILED (1)/gate-failed verdict line for the chatty failure"
  fi

  set_conf "$PS_SCRATCH" 'pre-commit|cmd /c "echo ok-probe & exit /b 0"'
  expect_rc pass "ps: chatty succeeding command still passes" "$PS_SCRATCH" ps_gate
  if grep -q "ok-probe" "$PS_SCRATCH/.test-out.log"; then
    ok "ps: chatty succeeding command's output stays visible"
  else
    bad "ps: chatty succeeding command's output was swallowed"
  fi
fi

# ---- ledger-mem: roster Status column (core 1.1.0) ---------------------------
# The roster board is the next worker's at-a-glance coordination surface: a
# real row (codename S<NNN>) with an empty or missing Status cell draws a
# warn-only nudge — never a failure, and legacy four-column rows warn too.
MEM_SCRATCH=${TMPDIR:-/tmp}/ledger-test-mem
rm -rf "$MEM_SCRATCH"
mkdir -p "$MEM_SCRATCH/.context_ledger/core" "$MEM_SCRATCH/.context_ledger/memory/office/agents"
cp -R "$CORE/bin" "$MEM_SCRATCH/.context_ledger/core/bin"
MEM_SH="$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem"
ROSTER="$MEM_SCRATCH/.context_ledger/memory/office/agents/roster.md"

cat > "$ROSTER" <<'EOF'
| Name | Codename | Model | Doing | Status | Status detail |
|------|----------|-------|-------|--------|---------------|
| Ada | S001 | m | reviewing the loop | Working | Phase 2 review, Step 9 |
| Kwame | S002 | m | docs pass | Done | Shipped: docs released |
EOF
if sh "$MEM_SH" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
   && ! grep -q "WARN roster.md" "$MEM_SCRATCH/.mem-out.log"; then
  ok "mem: filled Status cells pass check with no warn"
else
  bad "mem: filled Status cells flagged or check failed"
  tail -n 5 "$MEM_SCRATCH/.mem-out.log"
fi

cat > "$ROSTER" <<'EOF'
| Name | Codename | Model | Doing | Status | Status detail |
|------|----------|-------|-------|--------|---------------|
| Ada | S001 | m | reviewing the loop |  |  |
EOF
if sh "$MEM_SH" check > "$MEM_SCRATCH/.mem-out.log" 2>&1; then
  if grep -q "WARN roster.md" "$MEM_SCRATCH/.mem-out.log" \
     && grep -q "no Status" "$MEM_SCRATCH/.mem-out.log"; then
    ok "mem: empty Status cell draws a warn-only nudge"
  else
    bad "mem: empty Status cell not flagged"
  fi
else
  bad "mem: empty Status cell failed the check (should warn only)"
fi

cat > "$ROSTER" <<'EOF'
| Name | Codename | Model | Doing |
|------|----------|-------|-------|
| Ada | S001 | m | reviewing the loop |
EOF
if sh "$MEM_SH" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
   && grep -q "no Status" "$MEM_SCRATCH/.mem-out.log"; then
  ok "mem: legacy four-column row warns without failing"
else
  bad "mem: legacy four-column row not warned or check failed"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    MEM_PS_W=$(cygpath -w "$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1")
  else
    MEM_PS_W=$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1
  fi
  cat > "$ROSTER" <<'EOF'
| Name | Codename | Model | Doing | Status | Status detail |
|------|----------|-------|-------|--------|---------------|
| Ada | S001 | m | reviewing the loop |  |  |
EOF
  if "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$MEM_PS_W" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
     && grep -q "no Status" "$MEM_SCRATCH/.mem-out.log"; then
    ok "mem ps1: empty Status cell draws the same warn-only nudge"
  else
    bad "mem ps1: empty Status cell not warned or check failed"
  fi
fi
rm -rf "$MEM_SCRATCH"

# ---- ledger-mem: capped backlog queue (core 1.2.0) ---------------------------
# The backlog is a work queue, not a knowledge base: actionable rows only,
# capped at backlog_cap (default 20) — past it, check draws a warn-only
# nudge to prune into parking-lot.md. A backlog at or under the cap, and a
# parking lot of any size, stay silent.
MEM_SCRATCH=${TMPDIR:-/tmp}/ledger-test-mem-cap
rm -rf "$MEM_SCRATCH"
mkdir -p "$MEM_SCRATCH/.context_ledger/core" "$MEM_SCRATCH/.context_ledger/memory/office/agents" "$MEM_SCRATCH/.context_ledger/memory/office/tasks" "$MEM_SCRATCH/.context_ledger/memory/workflows"
cp -R "$CORE/bin" "$MEM_SCRATCH/.context_ledger/core/bin"
: > "$MEM_SCRATCH/.context_ledger/memory/office/agents/roster.md"
BACKLOG="$MEM_SCRATCH/.context_ledger/memory/office/tasks/backlog.md"
PARKING="$MEM_SCRATCH/.context_ledger/memory/office/tasks/parking-lot.md"

make_rows() { # $1 file, $2 count — B-<date> table rows, the shape check counts
  {
    echo '# Backlog'
    echo ''
    echo '### High Priority'
    echo ''
    echo '| ID | Summary |'
    echo '|----|---------|'
    i=1
    while [ "$i" -le "$2" ]; do
      printf '| B-2026-09-01-%d | do the thing %d |\n' "$i" "$i"
      i=$((i + 1))
    done
  } > "$1"
}

make_rows "$BACKLOG" 20
cat > "$PARKING" <<'EOF'
# Parking Lot

## Findings

| ID | Summary |
|----|---------|
| P-2026-09-01-1 | the queue was never the problem, the culture was |
EOF
if sh "$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
   && ! grep -q "WARN backlog.md" "$MEM_SCRATCH/.mem-out.log"; then
  ok "mem: backlog at the cap passes check with no warn"
else
  bad "mem: backlog at the cap (20 rows) warned"
  tail -n 5 "$MEM_SCRATCH/.mem-out.log"
fi

make_rows "$BACKLOG" 21
if sh "$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem" check > "$MEM_SCRATCH/.mem-out.log" 2>&1; then
  if grep -q "WARN backlog.md" "$MEM_SCRATCH/.mem-out.log" \
     && grep -q "past the cap of 20" "$MEM_SCRATCH/.mem-out.log" \
     && grep -q "parking-lot.md" "$MEM_SCRATCH/.mem-out.log"; then
    ok "mem: backlog past the cap draws a warn-only prune nudge"
  else
    bad "mem: over-cap backlog not flagged"
  fi
else
  bad "mem: over-cap backlog failed the check (should warn only)"
fi

# backlog_cap is read from history.conf — a raised cap silences the warn
printf 'backlog_cap=30\n' > "$MEM_SCRATCH/.context_ledger/memory/workflows/history.conf"
if sh "$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
   && ! grep -q "WARN backlog.md" "$MEM_SCRATCH/.mem-out.log"; then
  ok "mem: backlog_cap in history.conf raises the cap"
else
  bad "mem: backlog_cap conf key ignored"
  tail -n 5 "$MEM_SCRATCH/.mem-out.log"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    MEM_PS_W=$(cygpath -w "$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1")
  else
    MEM_PS_W=$MEM_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1
  fi
  rm -f "$MEM_SCRATCH/.context_ledger/memory/workflows/history.conf"
  if "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$MEM_PS_W" check > "$MEM_SCRATCH/.mem-out.log" 2>&1 \
     && grep -q "past the cap of 20" "$MEM_SCRATCH/.mem-out.log"; then
    ok "mem ps1: over-cap backlog draws the same warn-only nudge"
  else
    bad "mem ps1: over-cap backlog not flagged or check failed"
    tail -n 5 "$MEM_SCRATCH/.mem-out.log"
  fi
fi
rm -rf "$MEM_SCRATCH"

# ---- ledger-history: door-triggered close (core 1.1.0) ------------------------
# A registry past office_size (default 20) means the next worker through the
# door closes the office before working: status must say the close is due and
# name the door rule, and the close checklist must demand re-seeded entries
# that never cite the closed office's session numbers or codenames.
HIST_SCRATCH=${TMPDIR:-/tmp}/ledger-test-hist
rm -rf "$HIST_SCRATCH"
mkdir -p "$HIST_SCRATCH/.context_ledger/memory/office/agents"
cp -R "$CORE" "$HIST_SCRATCH/.context_ledger/core"
: > "$HIST_SCRATCH/.context_ledger/memory/office/agents/roster.md"
{
  i=1
  while [ "$i" -le 21 ]; do
    printf '## 2026-09-01 — Session %d\n- **Agent:** t | **Model:** m | **Platform:** p | **Role:** engineer | **Core:** 1.0.6\n- **Task:** filler\n- **Outcome:** done\n\n' "$i"
    i=$((i + 1))
  done
} > "$HIST_SCRATCH/.context_ledger/memory/office/agents/sessions.md"
# real-world shape: the scratch is a git repo (Cmd-Close checks for a dirty
# tree, and the ps1 port runs under Stop on native stderr)
git -C "$HIST_SCRATCH" -c init.defaultBranch=main init -q 2>/dev/null || git -C "$HIST_SCRATCH" init -q
git -C "$HIST_SCRATCH" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init

sh "$HIST_SCRATCH/.context_ledger/core/bin/ledger-history" status > "$HIST_SCRATCH/.hist-out.log" 2>&1
if grep -q "A close is DUE" "$HIST_SCRATCH/.hist-out.log" \
   && grep -q "The next worker through the door runs it" "$HIST_SCRATCH/.hist-out.log"; then
  ok "hist: status at office_size names the door rule (close is DUE)"
else
  bad "hist: status does not report the door-triggered close"
  tail -n 8 "$HIST_SCRATCH/.hist-out.log"
fi

sh "$HIST_SCRATCH/.context_ledger/core/bin/ledger-history" close > "$HIST_SCRATCH/.hist-close.log" 2>&1
if grep -q "Dry run" "$HIST_SCRATCH/.hist-close.log" \
   && grep -q "never cite" "$HIST_SCRATCH/.hist-close.log" \
   && grep -q "session numbers or codenames" "$HIST_SCRATCH/.hist-close.log" \
   && grep -q "numbering starts clean" "$HIST_SCRATCH/.hist-close.log"; then
  ok "hist: close checklist demands no old-office session numbers in re-seeds"
else
  bad "hist: close checklist lacks the no-leak re-seed rule"
  tail -n 12 "$HIST_SCRATCH/.hist-close.log"
fi
if grep -q "re-seed WORK, not knowledge" "$HIST_SCRATCH/.hist-close.log" \
   && grep -q "parking-lot" "$HIST_SCRATCH/.hist-close.log"; then
  ok "hist: close checklist demands re-seeding work, not knowledge (parking lot)"
else
  bad "hist: close checklist lacks the work-not-knowledge re-seed rule"
  tail -n 12 "$HIST_SCRATCH/.hist-close.log"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    HIST_PS_W=$(cygpath -w "$HIST_SCRATCH/.context_ledger/core/bin/ledger-history.ps1")
  else
    HIST_PS_W=$HIST_SCRATCH/.context_ledger/core/bin/ledger-history.ps1
  fi
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$HIST_PS_W" close > "$HIST_SCRATCH/.hist-close.log" 2>&1
  if grep -q "Dry run" "$HIST_SCRATCH/.hist-close.log" \
     && grep -q "never cite" "$HIST_SCRATCH/.hist-close.log" \
     && grep -q "numbering starts clean" "$HIST_SCRATCH/.hist-close.log"; then
    ok "hist ps1: close checklist carries the no-leak re-seed rule"
  else
    bad "hist ps1: close checklist lacks the no-leak re-seed rule"
    tail -n 12 "$HIST_SCRATCH/.hist-close.log"
  fi
fi
rm -rf "$HIST_SCRATCH"

# ---- ledger-mem prune: log compaction reports (core 1.1.0) -------------------
# prune stays advisory but must see all three compaction signals: a resolved
# inefficiency entry and a superseded ADR are archive-eligible, and 3+ entries
# sharing a Problem line surface as a roll-up candidate -- both ports. The
# closed marker counts ONLY from an entry's own **Status:** line: prose that
# merely mentions the words is not a marker, and a `<!-- -->` template
# comment is never segmented at all (its placeholder Status lines carry the
# words literally).
PRUNE_SCRATCH=${TMPDIR:-/tmp}/ledger-test-prune
rm -rf "$PRUNE_SCRATCH"
mkdir -p "$PRUNE_SCRATCH/.context_ledger/core/bin" "$PRUNE_SCRATCH/.context_ledger/memory/office/flaws" "$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies" "$PRUNE_SCRATCH/.context_ledger/memory/office/plans"
cp "$CORE/bin/ledger-mem" "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem"
cp "$CORE/bin/ledger-mem.ps1" "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1"
cat > "$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies/log.md" <<FIXTURE1
# Inefficiency Log
<!-- TEMPLATE -- copy below the last entry:
## YYYY-MM-DD -- T / m
- **Flaw:** placeholder
- **Status:** open | fixed in package <sha> | superseded by <something>
-->
## 2026-09-01 -- A / m
- **Problem:** flaky test on CI runner
- **Status:** open
## 2026-09-02 -- B / m
- **Problem:** flaky test on CI runner
- **Status:** open
## 2026-09-03 -- C / m
- **Problem:** Flaky  test on CI runner
- **Status:** open
## 2026-09-04 -- D / m
- **Problem:** unrelated one-off
- **Status:** RESOLVED -- installed psql
## 2026-09-05 -- E / m
- **Problem:** entry describing the compaction rule in prose
- **Root cause:** resolved/superseded entries move verbatim to the archive, so mentions of them appear in accepted entries too
- **Status:** open
FIXTURE1
cat > "$PRUNE_SCRATCH/.context_ledger/memory/office/plans/decisions.md" <<FIXTURE2
# Decisions
<!-- TEMPLATE:
## D-N: <short title> (YYYY-MM-DD)
- **Status:** accepted | superseded by D-M
-->
## D-1: use sh ports only (2026-09-01)
- **Status:** superseded by D-2
## D-2: keep both ports (2026-09-02)
- **Context:** the compaction rule moves resolved and superseded entries to the archive
- **Status:** accepted
FIXTURE2

sh "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem" prune > "$PRUNE_SCRATCH/.prune.log" 2>&1
if grep -q "1 marked resolved/superseded" "$PRUNE_SCRATCH/.prune.log" && grep -q "roll-up: 3 entries hit the same recurring thing (flaky test on ci runner)" "$PRUNE_SCRATCH/.prune.log" && grep -q "plans/decisions.md" "$PRUNE_SCRATCH/.prune.log" && grep -q "5 entries" "$PRUNE_SCRATCH/.prune.log" && grep -q "2 entries" "$PRUNE_SCRATCH/.prune.log"; then
  ok "prune: resolved entries + superseded ADR + 3-repeat roll-up all reported"
else
  bad "prune: compaction reports incomplete"
  cat "$PRUNE_SCRATCH/.prune.log"
fi
# the closed-marker is scoped to **Status:** lines and skips template comments:
# entry E mentions "resolved/superseded" in prose, accepted D-2 mentions them
# too, and both template placeholders say "superseded" / "fixed in package".
# None may be listed as eligible (--list names every candidate: D-2 resolved
# entry, the superseded D-1, and the roll-up instance line — three bullets).
sh "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem" prune --list > "$PRUNE_SCRATCH/.prune-list.log" 2>&1
if [ "$(grep -c '^    - ' "$PRUNE_SCRATCH/.prune-list.log")" -eq 3 ] \
   && ! grep -q "YYYY-MM-DD -- T" "$PRUNE_SCRATCH/.prune-list.log" \
   && ! grep -q "D-N" "$PRUNE_SCRATCH/.prune-list.log" \
   && ! grep -q "E / m" "$PRUNE_SCRATCH/.prune-list.log" \
   && ! grep -q "D-2: keep" "$PRUNE_SCRATCH/.prune-list.log"; then
  ok "prune: prose mentions + template comments are NOT archive-eligible"
else
  bad "prune: over-matches prose/template closed words"
  cat "$PRUNE_SCRATCH/.prune-list.log"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    PRUNE_PS_W=$(cygpath -w "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1")
  else
    PRUNE_PS_W=$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1
  fi
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$PRUNE_PS_W" prune > "$PRUNE_SCRATCH/.prune-ps.log" 2>&1
  if grep -q "1 marked resolved/superseded" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "roll-up: 3 entries hit the same recurring thing (flaky test on ci runner)" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "plans/decisions.md" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "5 entries" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "2 entries" "$PRUNE_SCRATCH/.prune-ps.log"; then
    ok "prune ps1: same archive-eligible + roll-up signals reported"
  else
    bad "prune ps1: compaction reports incomplete or diverging"
    cat "$PRUNE_SCRATCH/.prune-ps.log"
  fi
fi
# ---- ledger-mem prune --apply: mechanical move, roll-up stays manual (core 2.0.0) ----
# --apply must cut exactly the closed entries (D in inefficiencies, D-1 in
# decisions) verbatim into archive.md, leave every open entry (A/B/C's
# roll-up candidates, E, D-2) and the template comment untouched in the
# live log, and NOT attempt the 3-repeat roll-up (that stays a manual edit).
sh "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem" prune --apply > "$PRUNE_SCRATCH/.prune-apply.log" 2>&1
INEFF_LOG="$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies/log.md"
INEFF_ARCHIVE="$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies/archive.md"
DEC_LOG="$PRUNE_SCRATCH/.context_ledger/memory/office/plans/decisions.md"
DEC_ARCHIVE="$PRUNE_SCRATCH/.context_ledger/memory/office/plans/archive.md"
if grep -q "moved 1 entry to inefficiencies/archive.md" "$PRUNE_SCRATCH/.prune-apply.log" \
   && grep -q "moved 1 entry to plans/archive.md" "$PRUNE_SCRATCH/.prune-apply.log" \
   && ! grep -q "## 2026-09-04 -- D / m" "$INEFF_LOG" \
   && grep -q "## 2026-09-04 -- D / m" "$INEFF_ARCHIVE" \
   && grep -q "RESOLVED -- installed psql" "$INEFF_ARCHIVE" \
   && grep -q "## 2026-09-01 -- A / m" "$INEFF_LOG" \
   && grep -q "## 2026-09-05 -- E / m" "$INEFF_LOG" \
   && grep -q "TEMPLATE -- copy below the last entry" "$INEFF_LOG" \
   && ! grep -q "## D-1: use sh ports only" "$DEC_LOG" \
   && grep -q "## D-1: use sh ports only" "$DEC_ARCHIVE" \
   && grep -q "## D-2: keep both ports" "$DEC_LOG"; then
  ok "prune --apply: moves closed entries verbatim, leaves open entries + roll-up + template alone"
else
  bad "prune --apply: closed-entry move incorrect"
  cat "$PRUNE_SCRATCH/.prune-apply.log"
  echo "--- inefficiencies/log.md ---"; cat "$INEFF_LOG" 2>/dev/null
  echo "--- inefficiencies/archive.md ---"; cat "$INEFF_ARCHIVE" 2>/dev/null
fi
# a second --apply on the now-clean logs must be a no-op, not an error
sh "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem" prune --apply > "$PRUNE_SCRATCH/.prune-apply-2.log" 2>&1
if grep -q "nothing marked resolved/superseded" "$PRUNE_SCRATCH/.prune-apply-2.log"; then
  ok "prune --apply: idempotent -- nothing left to move reports cleanly"
else
  bad "prune --apply: re-running on a clean log misbehaves"
  cat "$PRUNE_SCRATCH/.prune-apply-2.log"
fi
rm -rf "$PRUNE_SCRATCH"

# ---- ledger-mem check: flaws_cap / inefficiencies_cap nudge (core 2.0.0) -----
# Mirrors the existing backlog_cap test shape: past the cap warns without
# failing; the conf key raises it. 16 entries vs. the default cap of 15.
CAP_SCRATCH=${TMPDIR:-/tmp}/ledger-test-logcap
rm -rf "$CAP_SCRATCH"
mkdir -p "$CAP_SCRATCH/.context_ledger/core/bin" "$CAP_SCRATCH/.context_ledger/memory/office/flaws" "$CAP_SCRATCH/.context_ledger/memory/workflows"
cp "$CORE/bin/ledger-mem" "$CAP_SCRATCH/.context_ledger/core/bin/ledger-mem"
{
  printf '# Flaws Log\n'
  i=1
  while [ "$i" -le 16 ]; do
    printf '## 2026-09-%02d -- T / m\n- **Flaw:** x\n- **Status:** open\n' "$i"
    i=$((i + 1))
  done
} > "$CAP_SCRATCH/.context_ledger/memory/office/flaws/log.md"
sh "$CAP_SCRATCH/.context_ledger/core/bin/ledger-mem" check > "$CAP_SCRATCH/.check.log" 2>&1
_cap_rc=$?
if [ "$_cap_rc" -eq 0 ] && grep -q "WARN flaws/log.md: 16 entries past the cap of 15" "$CAP_SCRATCH/.check.log"; then
  ok "mem: flaws.log past the default cap draws a warn-only prune nudge"
else
  bad "mem: flaws_cap default nudge missing or check failed"
  cat "$CAP_SCRATCH/.check.log"
fi
printf 'flaws_cap=20\n' > "$CAP_SCRATCH/.context_ledger/memory/workflows/history.conf"
sh "$CAP_SCRATCH/.context_ledger/core/bin/ledger-mem" check > "$CAP_SCRATCH/.check2.log" 2>&1 \
  && ! grep -q "WARN flaws/log.md" "$CAP_SCRATCH/.check2.log"
_cap2_ok=$?
if [ "$_cap2_ok" -eq 0 ]; then
  ok "mem: flaws_cap in history.conf raises the cap and silences the warn"
else
  bad "mem: flaws_cap override not honored"
  cat "$CAP_SCRATCH/.check2.log"
fi
rm -rf "$CAP_SCRATCH"

# ---- ledger-mem lint --tree: sweep old-session leaks (core 1.1.0) ------------
# A leak an earlier session committed into product code is stripped on sight;
# the --tree sweep finds it (the staged-diff lint can't). Scratch repo with one
# product file leaking ADR-3 and a .context_ledger/ path, one clean file, and a
# legitimate .context_ledger/memory file that must NOT be reported.
LINT_SCRATCH=${TMPDIR:-/tmp}/ledger-test-lint
rm -rf "$LINT_SCRATCH"
mkdir -p "$LINT_SCRATCH/.context_ledger/core/bin" "$LINT_SCRATCH/.context_ledger/memory/plans" "$LINT_SCRATCH/src"
cp "$CORE/bin/ledger-mem" "$LINT_SCRATCH/.context_ledger/core/bin/ledger-mem"
cp "$CORE/bin/ledger-mem.ps1" "$LINT_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1"
printf 'def load():\n    return 1  # see ADR-3 for the cap\n' > "$LINT_SCRATCH/src/a.py"
printf 'value = 2  # documented in .context_ledger/memory/plans/decisions.md\n' > "$LINT_SCRATCH/src/b.py"
printf 'clean = 3  # no ledger vocabulary here\n' > "$LINT_SCRATCH/src/ok.py"
printf 'ADR-3 is a memory file; it may reference itself.\n' > "$LINT_SCRATCH/.context_ledger/memory/plans/decisions.md"
( cd "$LINT_SCRATCH" && git -c init.defaultBranch=main init -q && git add -A \
  && git -c user.name=t -c user.email=t@t commit -q -m init )

sh "$LINT_SCRATCH/.context_ledger/core/bin/ledger-mem" lint --tree > "$LINT_SCRATCH/.lint.log" 2>&1
_lrc=$?
if [ "$_lrc" -ne 0 ] \
   && grep -q "src/a.py:2 cites an ADR reference" "$LINT_SCRATCH/.lint.log" \
   && grep -q "src/b.py:1 cites a .context_ledger/ path" "$LINT_SCRATCH/.lint.log" \
   && ! grep -q "src/ok.py" "$LINT_SCRATCH/.lint.log" \
   && ! grep -q "memory/plans/decisions.md cites" "$LINT_SCRATCH/.lint.log"; then
  ok "lint --tree: reports product leaks with file:line, skips .context_ledger + clean files"
else
  bad "lint --tree: wrong verdict or mis-scoped report"
  cat "$LINT_SCRATCH/.lint.log"
fi

# a leak-free tree passes
LINT_CLEAN=${TMPDIR:-/tmp}/ledger-test-lint-clean
rm -rf "$LINT_CLEAN"
mkdir -p "$LINT_CLEAN/.context_ledger/core/bin" "$LINT_CLEAN/src"
cp "$CORE/bin/ledger-mem" "$LINT_CLEAN/.context_ledger/core/bin/ledger-mem"
printf 'x = 1  # plain comment, nothing forbidden\n' > "$LINT_CLEAN/src/a.py"
( cd "$LINT_CLEAN" && git -c init.defaultBranch=main init -q && git add -A \
  && git -c user.name=t -c user.email=t@t commit -q -m init )
if sh "$LINT_CLEAN/.context_ledger/core/bin/ledger-mem" lint --tree > "$LINT_CLEAN/.lint.log" 2>&1; then
  ok "lint --tree: a leak-free product tree passes"
else
  bad "lint --tree: false positive on a clean tree"
  cat "$LINT_CLEAN/.lint.log"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    LINT_PS_W=$(cygpath -w "$LINT_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1")
  else
    LINT_PS_W=$LINT_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1
  fi
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$LINT_PS_W" lint --tree > "$LINT_SCRATCH/.lint-ps.log" 2>&1
  if [ $? -ne 0 ] \
     && grep -q "src/a.py:2 cites an ADR reference" "$LINT_SCRATCH/.lint-ps.log" \
     && grep -q "src/b.py:1 cites a .context_ledger/ path" "$LINT_SCRATCH/.lint-ps.log" \
     && ! grep -q "src/ok.py" "$LINT_SCRATCH/.lint-ps.log" \
     && ! grep -q "memory/plans/decisions.md cites" "$LINT_SCRATCH/.lint-ps.log"; then
    ok "lint --tree ps1: same report and scoping as the sh port"
  else
    bad "lint --tree ps1: wrong verdict or mis-scoped report"
    cat "$LINT_SCRATCH/.lint-ps.log"
  fi
fi
rm -rf "$LINT_SCRATCH" "$LINT_CLEAN"

# ---- UTF-8 encoding (core 1.0.2) --------------------------------------------
# Windows PowerShell 5.1 reads BOM-less files in the ANSI codepage unless
# -Encoding UTF8 is passed. The office migration rewrote history.conf through
# such a read and corrupted the em-dash in the template comment; the lockfile
# writer had the same class of bug (ASCII header instead of the sh port's
# em-dash, churning the file on every port alternation). Regressions, on a
# scratch project, against the ps1 edition only (the sh tools read raw bytes):
#   - a ps1 migrate over a UTF-8 history.conf holding an em-dash preserves the
#     em-dash bytes and still renames the group_size key;
#   - a ps1 verify writes a core.lock byte-identical to the sh port's
#     (em-dash present, no BOM).
if [ -n "$PS_BIN" ]; then
  ENC_SCRATCH=${TMPDIR:-/tmp}/ledger-test-enc
  rm -rf "$ENC_SCRATCH"
  mkdir -p "$ENC_SCRATCH/.context_ledger/memory/agents" "$ENC_SCRATCH/.context_ledger/memory/workflows"
  cp -R "$CORE" "$ENC_SCRATCH/.context_ledger/core"
  # flat-layout marker (memory/agents) so the office migration must fire; the
  # conf holds the real template comment with its em-dash, plus the legacy key.
  printf '# Session-group rotation config \xe2\x80\x94 read by ledger-history.\ngroup_size=20\n' \
    > "$ENC_SCRATCH/.context_ledger/memory/workflows/history.conf"
  CONF_W=$ENC_SCRATCH/.context_ledger/memory/workflows/history.conf
  if command -v cygpath >/dev/null 2>&1; then
    SYNC_PS_W=$(cygpath -w "$ENC_SCRATCH/.context_ledger/core/bin/ledger-sync.ps1")
  else
    SYNC_PS_W=$ENC_SCRATCH/.context_ledger/core/bin/ledger-sync.ps1
  fi
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$SYNC_PS_W" migrate --backfill-only >/dev/null 2>&1

  if grep -q "$(printf '\xe2\x80\x94')" "$CONF_W"; then
    ok "ps: migrate preserves the em-dash in history.conf (UTF-8 read)"
  else
    bad "ps: migrate corrupted history.conf non-ASCII (cp1252 regression)"
  fi
  if grep -q '^office_size=' "$CONF_W" && ! grep -q '^group_size=' "$CONF_W"; then
    ok "ps: migrate still renames group_size -> office_size"
  else
    bad "ps: migrate lost the config key rename"
  fi

  LOCK_W=$ENC_SCRATCH/.context_ledger/memory/core.lock
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$SYNC_PS_W" verify >/dev/null 2>&1
  if grep -q "$(printf '\xe2\x80\x94')" "$LOCK_W" \
     && [ "$(head -c 3 "$LOCK_W" | od -An -tx1 | tr -d ' ')" != "efbbbf" ]; then
    ok "ps: verify writes a core.lock byte-identical to the sh port (em-dash, no BOM)"
  else
    bad "ps: core.lock lost the em-dash or grew a BOM"
  fi
  rm -rf "$ENC_SCRATCH" 2>/dev/null || true
else
  say "  skip: UTF-8 encoding regressions (no powershell/pwsh on PATH)"
fi

# ---- ledger-sync harvest: office-era log paths ------------------------------
# Since core 1.0.0 the flaw/inefficiency logs live under memory/office/;
# harvest (package-mode, sh-only) must read the office layout or it collects
# NOTHING from every migrated project (flaws reported upstream, never
# harvested). Scratch package clone + sibling project checkout with open
# entries in both office logs and a [core-defect] override (overrides stay
# at the memory root in both layouts).
HV_SCRATCH=${TMPDIR:-/tmp}/ledger-test-harvest
rm -rf "$HV_SCRATCH"
mkdir -p "$HV_SCRATCH/pkg/core/bin" "$HV_SCRATCH/proj/.context_ledger/memory/office/flaws" \
         "$HV_SCRATCH/proj/.context_ledger/memory/office/inefficiencies" \
         "$HV_SCRATCH/proj/.context_ledger/memory/overrides"
cp "$CORE/bin/ledger-sync" "$HV_SCRATCH/pkg/core/bin/ledger-sync"
printf 'https://example.invalid/proj.git  bootstrapped=2026-09-14  core=1.1.2\n' > "$HV_SCRATCH/pkg/fleet.md"
cat > "$HV_SCRATCH/proj/.context_ledger/memory/office/flaws/log.md" <<'HVF1'
# Flaws (office)
## 2026-09-14 -- Tester / m (Session 1)
- **Flaw:** office-era flaw entry for the harvest regression.
- **Status:** open
HVF1
cat > "$HV_SCRATCH/proj/.context_ledger/memory/office/inefficiencies/log.md" <<'HVF2'
# Inefficiencies (office)
## 2026-09-14 -- Tester / m
- **Problem:** office-era inefficiency entry for the harvest regression.
- **Upstream:** candidate
HVF2
printf -- '- **[core-defect]** harvest regression override bullet (set by tester, 2026-09-14)\n' \
  > "$HV_SCRATCH/proj/.context_ledger/memory/overrides/rules.md"
( cd "$HV_SCRATCH/proj" && git -c init.defaultBranch=main init -q \
  && git remote add origin https://example.invalid/proj.git )
sh "$HV_SCRATCH/pkg/core/bin/ledger-sync" harvest > "$HV_SCRATCH/.harvest.log" 2>&1
if grep -q "proj: +1 flaws, +1 inefficiencies, +1 overrides" "$HV_SCRATCH/.harvest.log" \
   && ls "$HV_SCRATCH/pkg/inbox"/harvest-*.md >/dev/null 2>&1 \
   && grep -q "office-era flaw entry" "$HV_SCRATCH/pkg/inbox"/harvest-*.md \
   && grep -q "office-era inefficiency entry" "$HV_SCRATCH/pkg/inbox"/harvest-*.md; then
  ok "harvest: reads office-era memory/office/ logs (+ root overrides)"
else
  bad "harvest: missed the office-era layout"
  cat "$HV_SCRATCH/.harvest.log"
fi
rm -rf "$HV_SCRATCH"

rm -rf "$SH_SCRATCH" "${PS_SCRATCH:-}" 2>/dev/null || true

say ""
say "tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
