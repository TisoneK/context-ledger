# Design: Identity namespace, prose-vs-gate enforcement, and log lifecycle

**Status:** proposed — awaiting supervisor ruling (§6). No code yet; this
note captures the problem and the proposed direction for each piece.
**Author:** Soren (S021) · 2026-10-30
**Origin:** a supervisor design discussion. The supervisor named five
observations about the protocol; this note argues they collapse into three
root issues and proposes a direction for each.
**Target:** spans releases — the log-lifecycle piece is PATCH-sized (it
mostly enforces what already exists), enforcement is MINOR, the identity
namespace is the invasive one (touches the commit trailer, the heartbeat,
history-close — MAJOR if the codename format changes on disk).
**Evidence (grounded in the tree, 2026-10-30):**
- Naming: `ai-engineering-protocol-local.md` — "Pick a real name you like
  (any human name — John, Ada, Kwame, Mei; unique in the office)." No seed
  or theme list anywhere in `core/`.
- Codename: office-local `S<NNN>`; "numbering restarts in a new office, and
  old-office numbers never carry over"; re-seeded entries "never cite the
  closed office's session numbers or codenames … which point into the
  frozen copy the new office never reads."
- Roster schema: `Name | Codename | Model | Doing | Status | Status detail`
  (`ledger-mem` line 138) — no contributor/clone field.
- Enforcement already present: `ledger-guard` (heartbeat, `Ledger-Session`
  trailer, unattributed commit refused), push-check, `ledger-mem check`
  (dup/stale/cap warnings).
- Log lifecycle already present: `ledger-mem prune` / `prune --apply` moves
  entries marked `RESOLVED`/`superseded`/`fixed in package`/"no longer a
  flaw" **verbatim into a companion `archive.md`**; `flaws_cap`/
  `inefficiencies_cap` default 15; startup reads only the live log.

---

## 1. The five observations

From the discussion, in the supervisor's framing:

1. The sibling-agents-then-archive pattern is powerful and under-used.
2. Collaboration assumes **one** user/dev — with many contributors there is
   no way to know which clone belongs to whom.
3. Lately agents have to be **forced** to follow the protocol.
4. Agents across unrelated projects pick **almost the same names** without
   seeing each other, "as if something triggers naming"; and `S001` should
   encode office + session (e.g. `OF01SS01`). "Many flaws follow fleet."
5. The flaws/other logs **pile up and repeat** after they've served their
   purpose — why keep them?

## 2. They are three root issues

**Root A — identity is single-stream, office-local, and un-namespaced
(covers #2 and #4).**

- The name clustering is **not** the protocol triggering anything — names
  are free-choice, no seed exists. The cluster is the *model's own naming
  prior*: one model + one free-choice prompt yields the same handful of
  names across every project. Asking more politely cannot fix this; the
  name has to stop being the identifier where uniqueness matters.
- The codename **already knows it is ambiguous** and works around it:
  `S001` is office-local, and the rules forbid citing old codenames
  because they point into a frozen copy. That prohibition *is* the symptom.
  Encoding office (and contributor) into the id — the supervisor's
  `OF01SS01` — makes it globally self-describing and largely retires the
  "never cite old numbers" rule.
- Contributor identity is genuinely **missing from the ledger's own
  model**: `sessions.md` records the machine and git records the author,
  but the roster has no contributor field, so two devs' clones can both
  reach for `S001` and nothing in the ledger distinguishes them. This is
  the same crack as the codename: fold contributor into the id.

**Root B — too much of the protocol is voluntary prose, not a gate
(covers #3, and the enforcement half of #5).** Real gates exist
(`ledger-guard`, push-check, `ledger-mem check`), but check-in-first,
trimming, and re-seed discipline live in long prose and depend on the model
choosing to read and obey it. That dependency degrades with protocol
length, model, and context pressure — which is exactly "we have to force
it." "We keep forcing X" is the signal for *which* rule hasn't earned a
gate yet.

**Root C — the log lifecycle the supervisor wants already exists but is
unenforced (covers #5).** `ledger-mem prune` archives resolved entries
**verbatim** (it does not delete — consistent with "keep all bookkeeping").
The gap is that it is manual and depends on entries being *marked* closed.
So Root C is really a facet of Root B: a good mechanism left voluntary,
plus a discipline gap in marking entries resolved.

## 3. Proposed direction

### A. Identity namespace
- Treat the **codename as the real identity** and the human name as a
  friendly label. Give the codename a structured, globally-unique form:
  `<contributor>·<office>·<session>` (e.g. `TK·O3·S01`). Contributor is a
  per-clone id (configured once, or derived from `git config user.email`).
- Add a **contributor/origin column** to the roster and the session entry.
- Payoffs: cross-office/cross-project codename collisions become
  impossible; attribution ("whose clone?") is explicit; the "never cite old
  codenames" workaround can relax because ids no longer alias.
- **Cost (why this is the invasive one):** the codename is stamped into the
  `Ledger-Session:` commit trailer, the `.git/` heartbeat, events, reports,
  and history-close. A format change touches `ledger-guard`, `ledger-mem`,
  and the close flow, and needs a migration for existing offices.

### B. Prose → gate
- Enumerate every "you must" in the local rules and sort into *gateable*
  (fail-closed hook) vs *judgment* (stays prose). Candidates to gate:
  refuse a product commit before a roster row exists for this session;
  run housekeeping at exit instead of nudging.
- Shrink the prose as each rule migrates to a gate — the rules file is
  long enough that its length is itself a compliance risk.

### C. Log lifecycle
- Make `prune --apply` part of the **exit gate**, not a manual nudge, so
  resolved entries archive automatically.
- Enforce the **"mark it resolved"** step when a session claims to have
  fixed a logged flaw (so prune has something to act on), and keep the
  verbatim-archive behavior (nothing is dropped).

## 4. The through-line

Two moves cover all three roots: **give identity a real namespace, and
move obligations from prose into gates.** Root C is Root B applied to the
logs; Root A is its own schema change but points the same way — encode the
invariant (unique, attributable identity) into the format instead of
asking agents to maintain it by hand.

## 5. Scope / sequencing suggestion

1. **C first** — smallest, mostly enforcement of existing `prune`; immediate
   relief for the pile-up.
2. **B next** — pick the two or three highest-value "forced" rules and gate
   them; measure whether "forcing" drops.
3. **A last** — highest leverage but most invasive; settle the codename
   format and the migration before writing code. Decide the shape here
   before anything is stamped on disk.

## 6. Decisions needed from the supervisor

- **A1.** Adopt a structured codename (`contributor·office·session`)? If so,
  what contributor id — configured handle, or `git user.email`-derived?
- **A2.** Is cross-office/cross-project uniqueness a real requirement now
  (multiple contributors imminent), or is the single-owner assumption fine
  a while longer? This decides whether A is worth its migration cost.
- **B1.** Which "forced" rules hurt most right now? Those are the first gate
  candidates.
- **C1.** OK to make `prune --apply` run at exit automatically (verbatim
  archive, never delete)?

## 7. Supervisor ruling

_(to be filled when the supervisor rules — like the ruling subsection in
`sandbox-continuation-playbook.md`.)_
