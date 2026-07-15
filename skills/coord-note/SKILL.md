---
name: coord-note
description: >-
  Write a coordination-ledger entry so other sessions (trunk or stream, any
  worktree) learn about a change that affects them. Use PROACTIVELY right after
  shipping anything cross-cutting while parallel workstreams are active: a
  model/schema change, a rename, a new config key, a new convention, a landed
  seam, mass mechanical churn, a migration landed on trunk. Also for
  reservations (module ownership claims, landing freezes), and heads-ups
  (stream opened/landed, significant spend, large data reshape). Also when the
  user says "write a ledger entry", "coordination note", or "announce this to
  the other sessions".
---

# Coordination Note

Write one entry into the machine-global coordination ledger. Entries are instantly visible to every session in every worktree — no commit, no transport. This skill is the single authority for entry format and admission; the protocol rationale lives in `~/.claude/smallcoordination/WORKFLOW.md` §4.

## Admission rule — apply it first

**The pertinence test:** would a session doing *unrelated* work need to act differently after this change? If no, do not write an entry — the commit message is the record. Say so and stop. A healthy ledger gets a handful of entries per week, not per session.

## Procedure

1. Derive the project dir and create it if needed:
   ```bash
   PROJ=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
   mkdir -p ~/.claude/smallcoordination/$PROJ
   ```
2. Pick exactly one type:
   - `reservation` — a claim on future namespace: module ownership ("the stream owns restructuring X; trunk limits itself to small fixes there"), a landing freeze, a planned rename wave. State exactly what is claimed and until when.
   - `breaking` — a shipped change others must adapt to: schema/model changes, renames, API contract changes, behavior changes in shared subsystems, mechanical-churn slices.
   - `convention` — a new rule effective immediately: a landed seam ("new code takes identity from `get_current_user()`, never a literal"), a new standard, a new required setup step.
   - `heads-up` — FYI with side effects: stream lifecycle events, significant spend, large data reshape, a gnarly merge resolution that would surprise someone.
3. Write the file — name it `YYYY-MM-DD-HHMM_<type>_<branch>_<slug>.md` (the type token lets readers find standing reservations from `ls` alone; distinct names make concurrent writers safe), keep the whole entry under ~20 lines:

   ```markdown
   type: reservation | breaking | convention | heads-up
   branch: <branch the work happened on>
   commit: <sha if committed, else "uncommitted">
   date: <YYYY-MM-DD HH:MM local>
   author: <session/actor — e.g. "trunk session (plugin)", "feat_multitenant session">
   affects: <paths, modules, tables, config keys — the things another session would touch>

   ## What changed / what is claimed
   <2-6 lines. Facts, not narrative.>

   ## What other sessions must do
   <The actionable part — "stop using X", "new code goes through Y", "sync before touching Z",
   "trunk: hold migrations until the landed entry". Nothing to put here = the entry fails
   the pertinence test; don't write it.>
   ```

4. Confirm in one line: type, filename, and the one-sentence "what others must do".

## Rules

- **Append-only.** Never edit a written entry; a correction or revocation is a new entry referencing the old one.
- Entries are operational signaling, not documentation — point at code/docs/commits rather than restating them.
- This ledger is machine-local and never committed to any repo.
