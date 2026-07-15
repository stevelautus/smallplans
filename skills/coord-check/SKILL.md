---
name: coord-check
description: >-
  Read the coordination ledger and report the standing obligations it imposes on
  this session (active freezes, reservations, landed seams, breaking changes,
  open streams). Use at session start whenever ~/.claude/smallcoordination/<project>/
  has entries, and when the user asks about coordination state or active streams.
model: claude-haiku-4-5
context: fork
agent: Explore
---

# Coordination Check

You run in a forked context with no conversation history: derive everything from git and the filesystem. Your final message is the ONLY thing the calling session sees — make it the complete obligations report and nothing else (no preamble, no narration of steps).

This is the trunk-session citizen check; stream worktrees get the deeper version inside the **smallplans:stream-work** skill. Read-only: never write or edit ledger entries (that is the **smallplans:coord-note** skill) and never sync (that is the **smallplans:stream-sync** skill).

## Procedure

1. Locate the ledger (one Bash call):
   ```bash
   PROJ=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
   ls ~/.claude/smallcoordination/$PROJ/*.md 2>/dev/null
   ```
   No directory or no entries → your final message is exactly "No parallel workstreams; nothing applies." Stop.

2. Read the working set in ONE Bash call — the 8 newest entries plus every reservation entry regardless of age. Filenames carry the type as the second underscore-delimited token (`YYYY-MM-DD-HHMM_<type>_<branch>_<slug>.md`); if filenames lack a type token (older convention), find reservations with `grep -l "^type: reservation" *.md` instead.
   ```bash
   cd ~/.claude/smallcoordination/$PROJ && for f in $( (ls *.md | tail -n 8; ls *_reservation_*.md 2>/dev/null) | sort -u ); do echo "=== $f ==="; cat "$f"; done
   ```
   Read nothing else: `WORKFLOW.md`, `README.md`, `TEMPLATE.md`, charter docs, and repo files are out of scope for this skill.

3. Release-closure for reservations: a reservation may have been released by an entry that is no longer among the 8 newest — for EACH reservation found, grep the ledger for entries that reference its timestamp and read any hits not already in your set:
   ```bash
   cd ~/.claude/smallcoordination/$PROJ && grep -l "<HHMM-of-reservation>" *.md
   ```

4. Determine what the current checkout is (one Bash call):
   ```bash
   [ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ] && echo main-checkout || echo stream-worktree; git branch --show-current
   ```

5. Distill obligations for the calling session:
   - A reservation is STANDING only if no later entry releases or revokes it (look for "released", "revoked", "freed", or a close-out/landed entry naming it). Released → "none standing".
   - Freeze = an unrevoked landing-freeze reservation → no new migrations, no new config keys until the landed entry.
   - Landed seams / conventions bind all new code; one line each.
   - Breaking changes matter only if unabsorbed; if a later entry shows them synced/absorbed, say "absorbed".
   - Open streams: name, branch, ports/DBs it owns, charter path — whatever the read set states.

6. Output exactly this block as your final message (≤25 lines; cite the source entry filename for every obligation):

   ```
   ## Coordination check — <project>
   Ledger: <N> entries; read <M> (8 newest + reservations + release-closure)

   - **Freeze:** <none active | ACTIVE — what, until when (file)>
   - **Reservations standing:** <none | claim + until-when (file)>
   - **Seams/conventions to honor:** <one line each (file)>
   - **Breaking changes to absorb:** <none | absorbed | one line each (file)>
   - **Open streams:** <name, branch, ports/DBs, charter (file)>
   - **This checkout:** <trunk — trunk-binding obligations | stream worktree <branch> — invoke smallplans:stream-work to implement; invoke smallplans:stream-sync first if trunk has moved>

   These obligations bind the session; re-check at natural boundaries if it runs long.
   ```
