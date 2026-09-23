# Environments (update in place)

Machines and sandboxes agents have run on, and what it takes to work on
this project from each. One block per environment; update the matching
block (and its "last verified" date) every time you run on it again.

## Rules

1. **Match before you add.** At session start, check whether the machine
   you're on already has a block (use its "Identify by" line). Update the
   match; add a new block only for a genuinely new environment.
2. **Record what you verified, not what you assume.** A command belongs
   under "Verified commands" only after it ran successfully on this
   environment, this project.
3. **Agents never delete blocks.** An environment the project no longer
   uses may be pruned by the user; if you can't verify a block, leave it
   alone — its last-verified date already says how stale it is.
4. **Machine facts only.** Secret values go in `secrets/`; user
   preferences in `user/`; project-wide decisions in `plans/`.

<!-- TEMPLATE — one block per environment:
---
## <stable label — hostname, "Z sandbox", "GitHub Actions ubuntu-24.04"> (last verified YYYY-MM-DD)
- **Identify by:** <how an agent recognizes this env — hostname, $USER, workspace path>
- **OS:** <e.g., macOS 15.5 / Ubuntu 24.04 sandbox>
- **Runtimes:** <node X, python Y, ...>
- **Package manager:** <npm/bun/pnpm/pip/...>
- **Verified commands:** <install / test / lint / typecheck / dev-server commands that actually worked here, with cwd if it matters>
- **Quirks:** <e.g., "no psql installed", "port 3000 usually taken", "system Python locked down">
-->

## Lameck's Windows workstation (last verified 2026-09-14)
- **Identify by:** win32 10.0.26200 x64, user `Lameck`, workspace `C:\Users\Lameck\Tisone\context-ledger`, shell Git Bash
- **OS:** Windows 11
- **Runtimes:** Git Bash (POSIX sh, GNU sed/awk, od, sha256sum, cygpath, xargs -0), Windows PowerShell 5.1, Python 3 (used only for JSON validation and to script em-dash-safe file edits, since Git Bash heredocs mangle backslashes)
- **Package manager:** none needed — tooling is pure sh + ps1
- **Verified commands:** `sh core/bin/ledger-sync verify|manifest|bootstrap|update core`; `sh tests/run-tests.sh` (package suite, 34/34 green on sh + a ps1-gated subset); `.context_ledger/core/bin/ledger-gates run pre-commit|checkpoint` (sh + .ps1); `.context_ledger/core/bin/ledger-collab emit|status|check` (sh + .ps1); `.context_ledger/core/bin/ledger-mem check|lint|lint --tree|prune|closeout` (sh + .ps1, output verified identical across ports); `.context_ledger/core/bin/ledger-history status|close` (dry run) — both ports
- **Quirks:** Git Bash `/tmp` is not a Windows path for python (use `cygpath -w`); JSON strict profile needs LF + UTF-8 without BOM — ps1 writers must use `[IO.File]::WriteAllText`, never `Set-Content` (BOM breaks the sh reader); repo `.gitattributes` enforces `eol=lf`; `cp -R SRC DST` where `DST` is a pre-existing dir nests the copy (`DST/SRC`) — create the parent, not the leaf, before `cp -R`; Git Bash `<<EOF` heredocs collapse `\\`→`\`, so a literal backslash in python/awk edit scripts must be built via `chr(92)`, not written as `\\`

## Tisone's Windows workstation (last verified 2026-09-23)
- **Identify by:** win32 10.0.26200 x64 (MINGW64_NT-10.0-26200), shell Git Bash, user `tison`, workspace `C:\Users\tison\Dev\context-ledger` — note this is a *different* user/workspace from "Lameck's Windows workstation" above (same Windows build); if they are one machine under two accounts, merge the two blocks
- **OS:** Windows 11 (10.0.26200)
- **Runtimes:** Git Bash (POSIX sh, GNU sed/awk, od, sha256sum, cygpath), **Windows PowerShell 5.1.26100.9444 and pwsh 7.6.6 (both on PATH — the release gate for ps1 ports is testable here)**, Python 3.14.2, git 2.55.0.windows.5
- **Package manager:** none needed — tooling is pure sh + ps1
- **Verified commands:** `sh core/bin/ledger-sync manifest|verify`; `powershell -NoProfile -ExecutionPolicy Bypass -File core/bin/ledger-sync.ps1 verify` and the same under `pwsh`; `sh tests/run-tests.sh` (63/63 green, includes the ps1 half under both engines); `sh .context_ledger/core/bin/ledger-gates run pre-commit|integration|exit`; `sh .context_ledger/core/bin/ledger-collab emit|status`; `sh .context_ledger/core/bin/ledger-mem check|lint|prune`; `sh .context_ledger/core/bin/ledger-state generate` — plus every `.ps1` twin of the above under both 5.1 and 7
- **Quirks:** a Windows console renders the ports' em-dashes (U+2014) through the console codepage's best-fit mapping, so captured output shows a plain hyphen even though the character is correct in-process (compare bytes or code points, not glyphs, when verifying non-ASCII); `powershell` 5.1 is the engine the `.cmd` launchers use, so a port must parse under it even when `pwsh` is the shell in use; Git Bash `/tmp` is not a Windows path for python (use `cygpath -w`); `cp -R SRC DST` where `DST` is a pre-existing dir nests the copy (`DST/SRC`) — create the parent, not the leaf; `ledger-sync manifest` refuses to run inside a project layout (package mode only), so scratch test fixtures must be laid out as `pkg/core/`
