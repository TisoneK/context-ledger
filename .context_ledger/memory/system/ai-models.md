# Agent + Model Registry (update in place)

Which agents and models have worked on this repo — and what they've
shown they can and can't do here. Update your row each session (last
seen + session count); add a row only if this **(agent, model) pair** is
new. The Observations section is how the user learns which agent to hand
which task, and how agents learn a predecessor's blind spots (and verify
its work accordingly).

> **Update in place — do NOT append a duplicate.** This is not an
> append-only log. There is exactly one row per (agent, model) pair: to
> correct a count, model note, or date, **edit that row** — its prior value
> is safe in git history, so you lose nothing. Never add a second row for a
> pair that already exists (that is how a registry ends up with two rows
> and conflicting counts). Different models for the same agent are separate
> rows — that is expected, not a duplicate. `sh .context_ledger/core/bin/ledger-mem
> check` (Windows: the `.ps1`) flags a duplicated (agent, model) key.

<!-- TEMPLATE — one row per agent+model pair:
| <agent name> | <model id> | YYYY-MM-DD | YYYY-MM-DD | <count> |
-->

| Agent | Model | First seen | Last seen | Sessions |
|---|---|---|---|---|
| Ada | glm-5.3-flash | 2026-09-10 | 2026-09-12 | 2 |
| Noor | glm-5.3-flash | 2026-09-11 | 2026-09-11 | 1 |
| Milo | glm-5.3-flash | 2026-09-11 | 2026-09-11 | 1 |
| June | glm-5.3-flash | 2026-09-11 | 2026-09-11 | 1 |
| Ines | glm-5.3-flash | 2026-09-12 | 2026-09-12 | 1 |
| Zuri | glm-5.3-flash | 2026-09-14 | 2026-09-14 | 1 |

## Observations

Concrete, evidence-based capabilities and limits — things demonstrated
in this repo's sessions, not marketing claims or self-assessment.
Update in place when a newer session contradicts an old observation.

<!-- TEMPLATE — one bullet per observation:
- **<agent> / <model>:** <what was observed — concrete and checkable, e.g. "Read tool truncates files >500 lines; needs offset/limit", "SSRF fix shipped with regression test, verified green"> (YYYY-MM-DD)
-->

- **Ada / glm-5.3-flash:** strict-profile JSON (one "key": value per line, escaped body) round-trips exactly through pure POSIX sh readers (sed/awk) and Windows PowerShell `ConvertFrom-Json` alike; PowerShell gotcha surfaced and fixed — a bare `-or` between two command calls inside `if()` does not evaluate as two boolean results, so parenthesize or name the booleans (2026-09-10)
- **Noor / glm-5.3-flash:** verified on this machine that a PowerShell gate command whose pipeline has two external stages masks an earlier failure ($LASTEXITCODE ends up the tail's), while a `Tee-Object` tail preserves the tool's exit code — the parser-audit rule in ledger-gates.ps1 1.0.1 is built on that distinction; PS 5.1 `Parser::ParseInput/ParseFile` returns errors for 5.1-hostile syntax rather than throwing (2026-09-11)
- **Kai / glm-5.3-flash:** Windows PowerShell 5.1 parses BOM-less .ps1 source as cp1252 — a non-ASCII string literal in ps1 source double-encodes on write (em-dash literal → `â€"` bytes); keep ps1 string literals pure ASCII and emit non-ASCII output via `[char]0x2014`-style code points. Same class: `Get-Content` without `-Encoding UTF8` reads BOM-less files as cp1252. (2026-09-11)
- **Milo / glm-5.3-flash:** in PowerShell, a re-emit loop of `Write-Host` resets `$?` — a child's verdict must be judged BEFORE its captured output is re-emitted, or a chatty failing child reads as success (the naive capture patch for the Run-One flaw would have swapped one mask for another). Also: `Write-Host` output from a `powershell.exe -File` invocation lands in redirected stdout, so gate-log assertions can rely on it; and `sh`-invoked `cmd /c "a & b"` under Git Bash mangles args so cmd starts interactively — probe the port that carries the flaw. (2026-09-11)
- **June / glm-5.3-flash:** concurrent-session release isolation — with a peer's uncommitted core edits sitting in the shared checkout, built an entire core release (manifest regen, verify, self-host copy) in an isolated worktree + branch off clean origin/main so the peer's bytes were never staged, hashed, or restored; rebased onto the peer's 1.0.3 when it landed and shipped 1.0.4 with no slot conflict. Also observed: pushing from a shared checkout whose HEAD is ahead of origin can silently publish a peer's local unpushed commits — fetch and diff against origin before every push. (2026-09-11)
- **Zuri / glm-5.3-flash:** a PowerShell function whose return value is captured (`$ok3 = Check-Roster`) also captures its whole success stream, so a `Say`/`Write-Output` warning inside it is swallowed and never reaches the operator — emit user-facing warnings from such functions via `[Console]::Out.WriteLine` (or stderr via the `ErrLine` pattern), not `Write-Output`; the DUP errors in ledger-mem survive capture only because `ErrLine` writes to `[Console]::Error`. Same class hit again under `Set-StrictMode`: `@(...)` must wrap a whole `git ls-files | Where-Object` pipeline, not just the leading call, or a single-file result is a scalar and `.Count` throws. Verified sh/ps1 parity by running both ports over identical scratch fixtures. (2026-09-14)
