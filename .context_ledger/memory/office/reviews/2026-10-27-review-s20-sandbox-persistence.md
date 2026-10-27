# Review — S020 — What survives a cloud-sandbox reset, and why

- **Agent:** Amani | **Model:** GLM (Z.ai) | **Platform:** Linux cloud sandbox (kata-containers / k8s pod) | **Date:** 2026-10-27
- **Task (supervisor):** "We need a research on what survives sandbox reset and why. This is no longer LocalMind's task — it's context-ledger's."
- **Method:** no speculation ahead of artifacts — live inspection of the mount table, `/start.sh` (PID 1's boot script), the host-written mirror manifest, the sandbox scaffold git repo (log/reflog/tree), and the commit-date timeline of three observed resets on the LocalMind host; then a 12-tier probe (`tests/sandbox-survival-probe.sh`, committed with this session) dropped on the host so the next reset completes the matrix empirically.

## 1. The environment

The sandbox is a kata-containers microVM in a k8s pod. Its root filesystem is an **ephemeral overlayfs** (`/proc/mounts`: `overlay ... lowerdir=/run/kata-containers/shared/containers/.../rootfs_lower, upperdir=/run/builtin_wlayer/.../upper`). Everything not on a separately-mounted durable volume dies with the container. The durable volumes visible on this host:

| Mount | Backing | Role |
|---|---|---|
| `/home/z/my-project/upload` | OSS (fuse.ossfs, rw) | user uploads; survives everything (mtime epoch 0) |
| `/home/official_skills` | OSS (ro) | skill zips, extracted into `skills/` at every boot |
| `/home/sync` | OSS (rw) | holds `repo.tar` — the boot-restore archive |
| `/tmp/my-project` and `/home/user_skills` | PolarFS (fuse.pfs, same volume) | the **host-written mirror** of the project's persisted files |

`/home/z/my-project` itself is on the ephemeral overlay. Its survival across resets is a **restore**, not persistence in place.

## 2. The mechanism (all claims artifact-backed)

Three cooperating pieces, each read directly off the host:

1. **The scaffold git repo.** `/home/z/my-project/.git` is a platform-owned repo (no remote). `/start.sh` inits it at first boot (`git add . && git commit -m "Initial commit"`), and the runtime harness auto-commits it (`git add -A`, UUID commit messages, author `Z User <z@container>`; observed live: commit `e5a2c20` fired 14 s after a worklog edit). Its `.gitignore` is deliberately narrow — exactly `skills/` and `node_modules/` — because `git add -A` must not sweep the ~10k-file skill tree (a boot-budget incident is documented in `/start.sh` comments).
2. **Two durable restore channels.** `/start.sh` at boot: if `/home/sync/repo.tar` exists it wipes the project (preserving the `upload/` mount) and extracts it — this tar **includes `.git`**, so scaffold history returns. The host also maintains a mirror at `/tmp/my-project` (PolarFS) containing the scaffold repo's **tracked files with a manifest** — `.initial_snapshot.json` maps every tracked path to its mtime, and its key set is byte-identical to `git ls-files` output. The mirror holds **no `.git`**.
3. **What git can see decides what survives.** The restore materializes exactly the tracked set: files with contents, and — critically — **embedded git repos as mode-160000 gitlinks**, i.e. a bare path entry holding only a commit SHA.

## 3. Direct artifacts

- `git ls-tree HEAD` in the scaffold shows `160000 commit dc0ea44c… LocalMind` — the LocalMind clone's entire working tree is invisible to persistence; only its HEAD SHA is recorded.
- The mirror's `LocalMind/` is an empty dir whose mtime (Oct 26 16:09) equals the original clone time — a gitlink materialized as an empty directory with the manifest-preserved mtime. Same for `research/deepseek-harness` (mtime = its clone time, empty).
- `.initial_snapshot.json` (mtime-annotated `git ls-files`) lists `worklog.md`, `.secrets/lm_pat`, `scripts/*`, `tool-results/*` — precisely the files that came back after the last reset, with their pre-reset mtimes (e.g. `.secrets/lm_pat` at Oct 26 16:16:27, sub-second exact).
- The scaffold's reflog contains exactly two commits ever: `Initial commit` (clean-boot init) and the one observed auto-commit.
- `/start.sh` documents the contract in its own comments: `repo.tar` written at pre-stop ("没有 repo.tar：要么是全新 chat，要么上次 pre-stop 写失败" — *no repo.tar: either a brand-new chat, or the last pre-stop write failed*), narrow `.gitignore` rationale, upload-mount preservation.

## 4. The three observed resets (LocalMind host, same chat)

| Reset | Boot evidence | What came back | What died |
|---|---|---|---|
| **R1** (before Oct 26 16:09 UTC) | no repo, no worklog, no .secrets (session log) — a **new chat** has no mirror/repo.tar | only the image scaffold | everything |
| **R2** (Oct 27 02:10 UTC) | scaffold `Initial commit` at 02:10:19 tracks **only 3 files** (`.env`, `.gitignore`, `download/README.md`) — clean-ish boot; tracked files returned afterwards via the mirror channel with preserved mtimes | worklog, `.secrets/`, `scripts/` (probe mtime Oct 26 16:45), empty LocalMind shell | LocalMind + research clone **contents** (gitlinks) |
| **R3** (Oct 27 06:12 UTC) | boot log: restore path (git setup 0 s, no re-init); `.env` mtime preserved at 03:03 — mirror-restored over the boot's own write | worklog (mtime 05:41), `.secrets/`, `scripts/`, `tool-results/`, empty repo shells | same gitlink collapse; both clones had to be re-fetched from GitHub |

The consequence chain is what the ledger protocol already insists on: **the only durable write in this environment is a push to the real remote.** The two LocalMind re-clones after R2/R3 were only possible because the ledger was on GitHub.

## 5. Survival matrix (same-chat reset, this host)

| Tier | Survives | Why |
|---|---|---|
| Scaffold-tracked files | **yes** (contents + mtimes, via mirror) | `git ls-files` is the snapshotter's file list |
| Scaffold `.git` history | **best-effort** (via `repo.tar`; observed stale by hours) | tar includes `.git`, but the archive lags the live repo |
| Embedded git clones | **no** — restored as empty dirs | gitlink: git records the SHA, never the tree |
| `gitignored` paths (`skills/`, `node_modules/`) | **no** | invisible to `git add -A` |
| Untracked files | **no** — unless the auto-commit fires first | trigger partially identified (see §8) |
| Empty directories | **no** | git cannot track them |
| `/tmp`, `/home/z` outside the project | **no** | ephemeral overlay |
| `upload/` | **always** | own OSS mount, excluded from every wipe |
| Root `.secrets/` (outside any repo) | **yes** — and this is a problem (§6) | the scaffold's `git add -A` tracks it; the mirror copies it |
| New chat | fresh scaffold | no mirror, no repo.tar ("Whoa, wat a nice clean project") |

The committed probe (`tests/sandbox-survival-probe.sh drop|report`) turns the remaining unknowns — size limits (32 MiB tier), untracked-vs-auto-commit timing, hidden files, deep nesting, `.secrets/` breadth — into a filled matrix at the next reset.

## 6. Security finding

The scaffold's `git add -A` sweeps **everything** outside its two-line `.gitignore` — including `.secrets/` at the project root and `.env`. Confirmed live: `.secrets/lm_pat` is a tracked blob in the scaffold repo and a key in the host mirror manifest. These artifacts never reach GitHub (no remote), but they **do leave the container** into platform storage (PolarFS/OSS) and are re-materialized into every future container of the same chat. The ledger's own rule ("values live only in the self-gitignored ledger secrets dir; that dir does not travel") is therefore not just convenient but the **safer** pattern on this host: in-repo secrets stay inside an embedded repo → gitlink collapse → they do **not** persist or travel, exactly as the secrets README intends. Root-level "secrets" dirs outside a repo get the opposite of the intended treatment. Protocol guidance worth adopting: never place secret files at the sandbox project root; treat the ledger secrets dir as the only secrets location, and re-provision root-level credentials per session.

## 7. What this changes for the protocol

1. **"Not done until pushed" is now evidence-backed as the durability boundary** — worth a line in the cloud edition: on containerized hosts the local filesystem is a cache with platform-managed eviction, not storage.
2. **Untracked work dies silently** — the S011 flaw (file left untracked at close) has a harsher enforcer here: the sandbox itself deletes it. Closeout discipline should include `git status --porcelain` empty on the *scaffold* too, not just the project repo.
3. **Re-cloning is an expected recovery step** on sandbox hosts, not an anomaly — the check-in flow already handles it; sessions should log it as R2/R3 did.
4. **Secrets placement** (§6) — add the root-level-secrets warning to the cloud edition's secrets handling.
5. **mtime forensics caveat**: preserved mtimes are restored from the manifest, so mtime alone does not prove a file was untouched across a reset — use content hashes (the probe's manifest carries SHA-256 for exactly this reason).

## 8. Open questions (for the probe to answer)

- The auto-commit fired 14 s after a worklog edit in this session, yet the pre-reset scaffold reflog had **no** auto-commits despite hours of file edits in the prior container — trigger unknown (image-version difference vs specific trigger paths). The T2 untracked tier is the diagnostic.
- `repo.tar` write cadence: observed mtime = boot+12 min on one host; the `src:` snapshot cadence of the PolarFS mirror is also unobserved (manifest writes seen at 02:22 and 07:47).
- Size ceiling: is the 32 MiB tier mirrored, truncated, or dropped?
- Whether the scaffold repo.tar restore or the mirror wins on conflict (observed mirror-over-tar for `.env`, single data point).

## 9. Notes for the next session

- Run `sh tests/sandbox-survival-probe.sh report` after the next reset and paste the matrix into this review's successor.
- The package suite on this host: **84 passed / 9 failed**, all failures pre-existing on `main` and confined to the `ledger-sync` `src:` source-resolution tests (upstream-fixture behavior differs under this host's git); none in guard/gates/state surfaces. Filed here as a record, not fixed in this session.
