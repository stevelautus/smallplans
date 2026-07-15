---
name: implement-plan
description: >-
  Execute a ratified plan document autonomously on a dedicated feature branch
  cut from an up-to-date main — the trunk-side sibling of /smallplans:stream-work, with
  no worktree or stream machinery. Use when the user runs /smallplans:implement-plan
  <path-to-plan-doc> or says "implement the plan", "pick up <plan doc> and
  build it", typically in a fresh ultracode session. This IS the kickoff:
  pointing a fresh session at a plan file replaces the old hand-written
  kickoff prompt. Refuses to run until the plan's ratification block is
  RATIFIED. A fresh start requires main to exactly match origin/main with no
  uncommitted changes — a failed check notifies the user and pauses in-session
  until they rectify and say resume. Designed for long uninterrupted runs: asks
  nothing that ratification settled, checkpoints with atomic green commits,
  recycles context per the context-kit, ends with an honest status; when the
  plan's executable work is complete it pushes the branch, opens the GitHub
  PR into main, and reports the exact PR URL — review and merge stay manual.
  Re-running the same command resumes from the plan's checkboxes and the
  commit trail.
---

# Implement Plan

Bootstrap, then run long. The plan document is the authority; this skill is the procedure for executing
it. The goal is a multi-hour run that never needs to ask — everything askable was settled at
ratification, and everything else is a defined hard stop.

## What the user typed after the command

The first token after `/smallplans:implement-plan` should be the plan doc's path. Anything after it is steering for
this run: which phase to prioritize, a tighter spend cap than the plan's, a stop time. Steering can
narrow the plan's authorizations for this run, never widen them. No path given → list the repo's plan
docs with their ratification status, newest first, and ask which one; do not guess.

## Bootstrap (before any feature work)

1. **Read the plan doc in full.** If its ratification block is not `RATIFIED`, implementation has not
   been authorized — stop and say exactly what's missing (this mirrors /smallplans:stream-work's charter gate).
2. **Coordination gate.** If `~/.claude/smallcoordination/<project>/` has entries, read them before touching
   code: an active landing freeze, a reserved module, or an unabsorbed breaking/convention entry can
   reshape or block this run. Honor what they impose.
3. **Branch setup.** Determine the feature branch name: steering may name it; else the plan doc's
   stated branch; else derive it from the plan filename (lowercase, non-alphanumerics to `_`, strip a
   trailing `_plan`) — e.g. `COUNTRY-COVERAGE-COMPLETION-PLAN.md` → `country_coverage_completion`.
   - **Resume:** if that branch already exists (or HEAD is already on it), check it out and continue —
     the fresh-start gate below does not apply. Uncommitted changes to tracked files on resume are a
     mismatch: gate pause (below) and surface them (untracked files are OK, noted).
   - **Fresh start:** all three must hold, each verified:
     (a) HEAD is on `main`;
     (b) after `git fetch origin`, `main` matches `origin/main` exactly — neither behind nor ahead
         (`git rev-list --left-right --count origin/main...main` reports `0 0`);
     (c) no uncommitted changes, staged or unstaged (`git status --porcelain`) — untracked files are
         OK, but list them in the run-plan block.
     Then `git checkout -b <branch>`. All run work happens on this branch; `main` is never committed to.
   - **Gate pause — any check fails:** this is a pause, not a run-end hard stop (nothing has started).
     Notify the user: which check(s) failed, the observed state (current branch, ahead/behind counts,
     the dirty files), and the likely remedy. Rectify NOTHING yourself — no pull, stash, commit, or
     reset; fixing the state is the user's. Then end the turn and wait. When the user says to resume,
     re-run this step from the top (fetch included — the state has changed) and proceed once green;
     still failing → pause again the same way.
4. **Orient.** Read the project's CLAUDE.md and the reference docs the plan names. Verify the starting
   state matches the plan's stated assumptions: suite green, migrations current (branch and tree state
   are owned by the previous step). A mismatch the plan didn't anticipate is a hard stop, not something
   to silently absorb.
5. **Locate progress and state the run plan.** Plan checkboxes plus `git log` since the plan's commit
   say where work stands. State in one short block: phases this run will execute (default: ALL remaining
   unblocked phases — steering may narrow this; context size never does), the envelope remaining, any
   steering. Then go — do not wait for confirmation; ratification already happened.

## The run loop

- **Atomic green commits.** Small commits, suite-relevant tests green per commit, full suite at phase
  boundaries. The commit trail plus the plan's checkboxes are the resume anchor — a run killed at any
  point resumes cleanly with the same `/smallplans:implement-plan <path>`.
- **Checkpoint at every commit and phase boundary:** if coordination is active, glance at the ledger
  (`ls ~/.claude/smallcoordination/<project>/ | tail -5`) and react to new entries that touch this work.
- **Context checkpoint (context-kit).** Same cadence: run the context measurement in
  `~/.claude/context-kit/RECYCLING.md` and follow it — over the threshold → overwrite this checkout's
  rolling handoff (`ROLLING-HANDOFF.xml`); after any compaction → re-orient from disk per the
  hook-injected instructions, then continue the run. Context pressure is NEVER a run-end condition: do
  not wind down or end a run because the compaction threshold is near — refresh the handoff and work
  straight through the flush; surviving it is what the kit is for. If that file is missing, the kit was
  rolled back — skip this bullet.
- **Stay on the feature branch.** The bootstrap branch is the only one this run touches: no further
  branches or worktrees, no merges, no mid-run pushes. The only push is the closeout publish (below);
  reviewing and merging the PR are the user's attended acts unless the plan explicitly grants otherwise.
- **Migrations** are trunk-numbered per project norms. If a stream is open, a migration landed here is
  exactly the kind of cross-cutting fact other sessions need: write a ledger entry.
- **Ledger duties.** Anything shipped that passes the pertinence test (schema change, rename, new config
  key, new convention) → the **smallplans:coord-note** skill, when coordination is active.
- **Spend governance.** Track app-level LLM spend against the plan's envelope using the plan's metering
  mechanism. Approaching the envelope → finish to a safe point and stop.
- **Subagents and ultracode.** In ultracode sessions, orchestrate phases with workflows per the standing
  ultracode rules. Subagents inherit this checkout — do not give DB-touching subagents
  `isolation: "worktree"` in projects whose DB naming keys off the worktree directory; a temporary
  worktree points them at databases that don't exist.

**Pre-authorized by the ratified plan (never ask mid-run):** spend up to the envelope; executing the
phase plan including minor documented deviations; plus only what the plan's pre-authorization section
explicitly grants. **There is no standing destructive carve-out on trunk** — the dev/test databases are
shared with other sessions, so DB rebuilds/drops and any other destructive op require the plan's explicit
grant or live permission.

**Hard stops — commit green, update plan progress, write status, end the turn:**
1. Envelope reached.
2. A discovery that invalidates a plan assumption (structural deviation, not a minor one).
3. A starting-state or mid-run mismatch the plan didn't anticipate (failing baseline suite, mid-run
   branch surprises). Bootstrap branch/tree failures are step 3's gate pause, not a run end.
4. Anything outside pre-authorization: pushes other than the closeout publish, destructive ops, scope
   changes.
5. A suite that cannot be brought green within the current task's scope.
6. A coordination obligation that conflicts with the work (landing freeze, reserved module).

## Run end

A run ends ONLY when one of these holds — nothing else is an exit:

1. **No unblocked work remains**: every plan phase is complete, or every remaining phase is gated on an
   attended checkpoint (a walk), a user decision, or an external dependency the plan names.
2. **A hard stop fired** (the list above, plus any the plan adds).
3. **Steering for this run set a stop time or narrower scope**, and it has been reached.

A phase boundary is a checkpoint, not an exit: finishing a phase means checkpoint, then continue into
the next unblocked phase in the same run. Context pressure — approaching or undergoing compaction — is
never a run-end condition (see the context checkpoint bullet). Precedent from earlier runs that happened
to end at a phase boundary does not redefine this rule.

Closeout, once one of the three conditions holds: 1. Full suite, honest result. 2. Plan progress section
updated (phases checked, follow-ups queued, spend logged) and committed. 3. **Publish — only when end
condition 1 holds** (the plan's executable work is done): `git push -u origin <branch>`, then open the
PR into `main` with `gh pr create` — title from the plan, body summarizing what shipped, how it was
verified, and any gated follow-ups. If a PR for this branch already exists (a resumed run), push and
reuse it (`gh pr view --json url`). Never merge it — review and merge are the user's, done from the PR
page. A hard-stopped or steering-stopped run does not push. 4. If the run produced facts other sessions
need and coordination is active, a closing entry via **smallplans:coord-note**. 5. Status message: what shipped,
what's queued, WHICH end condition stopped the run, and the next step — after a publish, the exact full
PR URL so the user can navigate straight to review/merge (if `gh` fails, the pushed branch and the error
verbatim instead); otherwise, that the next session is `/smallplans:implement-plan <path>` again.
