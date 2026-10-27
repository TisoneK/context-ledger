#!/bin/sh
# sandbox-survival-probe.sh — tiered reset-survival probe for cloud sandboxes.
#
# WHY THIS EXISTS (S020 research, 2026-10-27): on the Z.ai cloud sandbox the
# project directory is an EPHEMERAL overlayfs; survival across a container
# reset is achieved by the platform persisting the *scaffold git repo's
# tracked files* (contents + mtimes) to a durable mirror, plus a repo.tar
# (with .git) on OSS. Everything git cannot see dies: embedded git clones
# (recorded as mode-160000 gitlinks -> restored as EMPTY dirs), gitignored
# paths, untracked files (until the runtime auto-commit sweeps them), and
# empty directories. This probe drops one marker per candidate survival tier
# and reports which survived a reset, turning folklore into a matrix.
#
# Usage:
#   sandbox-survival-probe.sh drop [project-root]   # create markers + MANIFEST.json
#   sandbox-survival-probe.sh report [project-root] # compare live state vs MANIFEST.json
#
# Run `drop` in a session; after the NEXT reset run `report` in the fresh
# sandbox (the probe dir itself is a tracked tier, so the manifest travels
# with it). Commit the manifest for a durable copy of the baseline.

set -u

ROOT="${2:-/home/z/my-project}"
P="$ROOT/probe-survival"
MANIFEST="$P/MANIFEST.json"
SNAPSHOT="/tmp/my-project/.initial_snapshot.json"   # host mirror manifest (PolarFS)

note() { printf '%s\n' "$*"; }

# ---- tier definitions ------------------------------------------------------
# path (relative to ROOT, or /absolute) | description
tier_paths() {
  cat <<EOF
probe-survival/T0-control.txt|T0 control: plain tracked-dir file
probe-survival/T2-untracked.txt|T2 left untracked (auto-commit trigger diagnostic)
node_modules/probe-T3-ignored.txt|T3a gitignored dir (node_modules/)
skills/probe-T3-ignored.txt|T3b gitignored dir (skills/)
probe-survival/embedded-repo/inner.txt|T4 embedded git repo (expect gitlink collapse)
probe-survival/T5-32MB.bin|T5 large file (32 MiB size-limit probe)
probe-survival/a/b/c/d/e/f/T6-deep.txt|T6 deeply nested path
/home/z/probe-T7-outside-project.txt|T7 outside project root (/home/z)
/tmp/probe-T8-tmp.txt|T8 /tmp (overlay: expect death)
.secrets/probe-T9-secrets-dir.txt|T9 root .secrets/ dir (platform-mirror probe)
probe-survival/.T11-hidden|T11 hidden file in tracked dir
probe-survival/T10-empty-dir/|T10 empty directory (git cannot track)
EOF
}

abs_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *)  printf '%s' "$ROOT/$1" ;;
  esac
}

tracked_by_scaffold() {  # $1 = abs path; 0 if tracked in the scaffold repo
  (cd "$ROOT" && git ls-files --error-unmatch -- "$1" >/dev/null 2>&1) \
    || (cd "$ROOT" && git ls-files --error-unmatch -- "${1#"$ROOT"/}" >/dev/null 2>&1)
}

# ---- drop ------------------------------------------------------------------
do_drop() {
  [ -d "$ROOT/.git" ] || { note "ERROR: $ROOT has no .git (scaffold repo expected)"; exit 2; }
  mkdir -p "$P/T10-empty-dir" "$P/a/b/c/d/e/f" "$ROOT/node_modules" "$P/embedded-repo"

  echo "survival probe T0 control — drop $(date -u +%FT%TZ)" > "$P/T0-control.txt"
  echo "survival probe T2 untracked — drop $(date -u +%FT%TZ)" > "$P/T2-untracked.txt"
  echo "survival probe T3a node_modules ignored" > "$ROOT/node_modules/probe-T3-ignored.txt"
  echo "survival probe T3b skills ignored" > "$ROOT/skills/probe-T3-ignored.txt"
  echo "survival probe T4 inner file of an embedded repo" > "$P/embedded-repo/inner.txt"
  dd if=/dev/urandom of="$P/T5-32MB.bin" bs=1M count=32 status=none
  echo "survival probe T6 deep" > "$P/a/b/c/d/e/f/T6-deep.txt"
  echo "survival probe T7 outside project root" > /home/z/probe-T7-outside-project.txt
  echo "survival probe T8 tmp" > /tmp/probe-T8-tmp.txt
  echo "survival probe T9 marker — this is NOT a secret, only a canary" > "$ROOT/.secrets/probe-T9-secrets-dir.txt"
  echo "survival probe T11 hidden" > "$P/.T11-hidden"
  : > "$P/T10-empty-dir/.keep-nothing" 2>/dev/null; rm -f "$P/T10-empty-dir/.keep-nothing"

  # T4: make embedded-repo a real git repo (the gitlink-collapse tier)
  (cd "$P/embedded-repo" && git init -q && git add inner.txt \
     && git -c user.email=probe@probe -c user.name=probe commit -qm "probe T4") 2>/dev/null

  # MANIFEST.json — the baseline the next session diffs against
  {
    printf '{\n'
    printf '  "dropped_at": "%s",\n' "$(date -u +%FT%TZ)"
    printf '  "scaffold_head": "%s",\n' "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"
    printf '  "tiers": [\n'
    tier_paths | while IFS='|' read -r rel desc; do
      ap="$(abs_path "$rel")"
      if [ -e "$ap" ]; then
        sz=$(wc -c < "$ap" 2>/dev/null || echo 0)
        case "$ap" in */) sz=0;; esac
        mt=$(stat -c %Y "$ap" 2>/dev/null || echo 0)
        if tracked_by_scaffold "$ap"; then tr=true; else tr=false; fi
        h=$( [ -f "$ap" ] && [ "$sz" -lt 52428800 ] && sha256sum "$ap" 2>/dev/null | cut -d' ' -f1 || echo "-")
        printf '    {"path": "%s", "desc": "%s", "exists": true, "size": %s, "mtime": %s, "tracked": %s, "sha256": "%s"},\n' \
          "$rel" "$desc" "$sz" "$mt" "$tr" "$h"
      else
        printf '    {"path": "%s", "desc": "%s", "exists": false},\n' "$rel" "$desc"
      fi
    done | sed '$ s/,$//'
    printf '  ]\n}\n'
  } > "$MANIFEST"

  note "drop complete: markers under $P + /home/z + /tmp; manifest at $MANIFEST"
  note "next: optionally 'git add probe-survival' in the scaffold repo to pin the tracked tier,"
  note "then run 'report' in the NEXT session (after a reset) to build the survival matrix."
  note "Also worth checking post-reset: $SNAPSHOT (host mirror manifest) — which tiers it lists."
}

# ---- report ----------------------------------------------------------------
do_report() {
  [ -f "$MANIFEST" ] || { note "ERROR: no manifest at $MANIFEST — run 'drop' first"; exit 2; }
  note "== sandbox survival report — $(date -u +%FT%TZ) =="
  git -C "$ROOT" log --oneline -2 2>/dev/null | sed 's/^/scaffold: /'
  note ""
  note "tier | exists | size-ok | mtime-ok | tracked | verdict"
  note "-----+--------+---------+----------+---------+-------"
  tier_paths | while IFS='|' read -r rel desc; do
    ap="$(abs_path "$rel")"
    line=$(grep -F "\"path\": \"$rel\"" "$MANIFEST" || :)
    exists_now=$([ -e "$ap" ] && echo yes || echo NO)
    case "$ap" in */) exists_now=$([ -d "$ap" ] && echo yes || echo NO);; esac
    if [ "$exists_now" = yes ]; then
      sz=$(wc -c < "$ap" 2>/dev/null || echo 0); case "$ap" in */) sz=0;; esac
      mt=$(stat -c %Y "$ap" 2>/dev/null || echo 0)
      base_sz=$(printf '%s' "$line" | sed -n 's/.*"size": \([0-9]*\).*/\1/p')
      base_mt=$(printf '%s' "$line" | sed -n 's/.*"mtime": \([0-9]*\).*/\1/p')
      size_ok=$([ -z "$base_sz" ] && echo "?" || { [ "$sz" = "$base_sz" ] && echo yes || echo DRIFT; })
      mtime_ok=$([ -z "$base_mt" ] && echo "?" || { [ "$mt" = "$base_mt" ] && echo preserved || echo CHANGED; })
      if tracked_by_scaffold "$ap"; then tr=yes; else tr=no; fi
    else
      size_ok="-"; mtime_ok="-"; tr="-"
    fi
    note "$rel | $exists_now | $size_ok | $mtime_ok | $tr | $desc"
  done
  note ""
  if [ -f "$SNAPSHOT" ]; then
    note "host mirror manifest: $SNAPSHOT (mtime $(stat -c %y "$SNAPSHOT" 2>/dev/null))"
    note "tiers present in host manifest (persisted by the platform snapshotter):"
    tier_paths | while IFS='|' read -r rel desc; do
      case "$rel" in /*) continue ;; esac   # absolute tiers live outside the project mirror
      grep -qF "\"$rel\"" "$SNAPSHOT" 2>/dev/null && note "  IN : $rel"
    done
  else
    note "host mirror manifest not found at $SNAPSHOT (mirror layout may differ on this host)"
  fi
  note ""
  note "verdict key: exists=yes survived the reset; mtime=preserved means restored from"
  note "the durable mirror (not rewritten); tracked=no + exists=yes means the platform"
  note "auto-commit swept it after drop (T2 diagnostic)."
}

case "${1:-}" in
  drop)   do_drop ;;
  report) do_report ;;
  *) note "usage: $0 drop|report [project-root]"; exit 1 ;;
esac
