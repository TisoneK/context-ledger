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
# sharing a Problem line surface as a roll-up candidate -- both ports.
PRUNE_SCRATCH=${TMPDIR:-/tmp}/ledger-test-prune
rm -rf "$PRUNE_SCRATCH"
mkdir -p "$PRUNE_SCRATCH/.context_ledger/core/bin" "$PRUNE_SCRATCH/.context_ledger/memory/office/flaws" "$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies" "$PRUNE_SCRATCH/.context_ledger/memory/office/plans"
cp "$CORE/bin/ledger-mem" "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem"
cp "$CORE/bin/ledger-mem.ps1" "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1"
cat > "$PRUNE_SCRATCH/.context_ledger/memory/office/inefficiencies/log.md" <<FIXTURE1
# Inefficiency Log
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
FIXTURE1
cat > "$PRUNE_SCRATCH/.context_ledger/memory/office/plans/decisions.md" <<FIXTURE2
# Decisions
## ADR-1: use sh ports only (2026-09-01)
- **Status:** superseded by ADR-2
## ADR-2: keep both ports (2026-09-02)
- **Status:** accepted
FIXTURE2

sh "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem" prune > "$PRUNE_SCRATCH/.prune.log" 2>&1
if grep -q "1 marked resolved/superseded" "$PRUNE_SCRATCH/.prune.log" && grep -q "roll-up: 3 entries hit the same recurring thing (flaky test on ci runner)" "$PRUNE_SCRATCH/.prune.log" && grep -q "plans/decisions.md" "$PRUNE_SCRATCH/.prune.log"; then
  ok "prune: resolved entries + superseded ADR + 3-repeat roll-up all reported"
else
  bad "prune: compaction reports incomplete"
  cat "$PRUNE_SCRATCH/.prune.log"
fi

if [ -n "$PS_BIN" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    PRUNE_PS_W=$(cygpath -w "$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1")
  else
    PRUNE_PS_W=$PRUNE_SCRATCH/.context_ledger/core/bin/ledger-mem.ps1
  fi
  "$PS_BIN" -NoProfile -ExecutionPolicy Bypass -File "$PRUNE_PS_W" prune > "$PRUNE_SCRATCH/.prune-ps.log" 2>&1
  if grep -q "1 marked resolved/superseded" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "roll-up: 3 entries hit the same recurring thing (flaky test on ci runner)" "$PRUNE_SCRATCH/.prune-ps.log" && grep -q "plans/decisions.md" "$PRUNE_SCRATCH/.prune-ps.log"; then
    ok "prune ps1: same archive-eligible + roll-up signals reported"
  else
    bad "prune ps1: compaction reports incomplete or diverging"
    cat "$PRUNE_SCRATCH/.prune-ps.log"
  fi
fi
rm -rf "$PRUNE_SCRATCH"

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

rm -rf "$SH_SCRATCH" "$PS_SCRATCH" 2>/dev/null || true

say ""
say "tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
