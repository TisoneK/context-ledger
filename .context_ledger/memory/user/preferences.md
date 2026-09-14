# User Preferences (update in place)

How the user likes things done **on this project**. Seeded from
Pre-Flight at bootstrap; grows as sessions reveal preferences —
corrections the user gives, patterns they approve, things they state
outright. This file exists so the user never has to give the same
correction twice.

## Learning rules

1. **Record preferences, not instructions.** A preference is standing:
   it would apply to future sessions ("plain-language changelog
   entries"). An instruction is one-off ("skip the tests this once") —
   it dies with the session and does not belong here.
2. **Every bullet carries provenance** — how and when it was learned:
   `(pre-flight)`, `(stated, YYYY-MM-DD)`, `(correction, YYYY-MM-DD)`,
   `(approved pattern, YYYY-MM-DD)`. An explicit statement or correction
   outranks an inferred pattern.
3. **Current-state file.** When the user changes their mind, update the
   bullet in place and refresh its provenance — don't keep the stale
   version. History lives in the session log, not here.
4. **A session instruction beats a recorded preference for that
   session.** Follow the instruction; afterwards, if it looked like a
   standing change of mind, update this file.
5. **Committed to git — keep it professional.** Working-style facts
   only. Never personal details, never opinions about people, never
   credentials.

<!-- TEMPLATE — keep these headings; add bullets under each as learned.
Format: - <preference> — <how to apply it> (provenance, YYYY-MM-DD)
## Workflow
- <e.g., push to main directly; one logical change per commit> (pre-flight)

## Communication
- <e.g., plain-language changelog, technical detail in reports> (stated, 2026-07-11)

## Code style
- <e.g., comment the why not the what; prefer DRY helpers> (correction, 2026-07-11)

## Review depth
- <e.g., fix safe issues, flag architectural ones for approval> (pre-flight)

## Risk & approvals
- <e.g., never bump a major version without flagging it; schema changes need explicit approval> (correction, 2026-07-11)
-->

## Workflow

## Communication
- Reports the session delivers — the review report and the chat summary — must read human and simple: plain sentences, outcome first, no corporate skeleton, no protocol jargon. The mandated report structure (Executive Summary → Discovery Phase → …) was flagged as too complicated and robotic; core 1.0.4 replaced it with a voice spec. (correction, 2026-09-11)

## Code style

## Review depth
- An outside review handed to the agent (of the project or of its work) is input, not final say: apply own creative judgment on top, disagree where the review's calls are weak, and say so plainly rather than implementing it verbatim. (stated, 2026-09-14)

## Risk & approvals

## Workflow
- The user runs multiple agent sessions concurrently (fleets); cross-session coordination — sequencing releases, resolving collisions — is relayed by the supervisor between sessions. (observed, 2026-09-10)
- When a session's own conduct violates the protocol it is shipping, the user expects the miss named plainly and logged as a flaw, not smoothed over. (correction, 2026-09-10)
