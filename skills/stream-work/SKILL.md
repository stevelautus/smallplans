---
name: stream-work
description: >-
  Start or resume an autonomous implementation session inside a parallel-dev
  stream worktree: orient from the coordination ledger and charter, sync with
  trunk if triggered, then execute the charter's phases in a long uninterrupted
  run under the stream autonomy rules (checkpoint cadence, safe-point syncs,
  pre-authorized envelope, hard stops). Use when the user says "work the
  stream", "implement the charter", "continue the stream work", or runs
  /smallplans:stream-work from a stream worktree. Pairs with /smallplans:stream-open. Designed for
  multi-hour autonomous runs, including ultracode sessions.
---

# Stream Work

Bootstrap, then run long. This skill is the executable form of `~/.claude/smallcoordination/WORKFLOW.md` §9 (autonomous implementation sessions); that doc is the authority, this is the procedure. The goal is a 2–3 hour run that never needs to ask — everything askable was settled at charter ratification, and everything else is a defined hard stop.

## What the user typed after the command

Text after `/smallplans:stream-work` is steering for this run: which phase to prioritize, a tighter spend cap than the charter's, a stop time. Fold it in; steering can narrow the charter's authorizations for this run, never widen them.

## Bootstrap (before any feature work)

1. **Verify location.** You must be in a stream worktree: `git rev-parse --git-dir` differs from `--git-common-dir`, and the branch is `feat_*`. Otherwise stop and say where this must run. Derive:
   ```bash
   COMMON="$(git rev-parse --path-format=absolute --git-common-dir)"
   PROJ="$(basename "$(dirname "$COMMON")")"
   ```

2. **Read the ledger** (`~/.claude/smallcoordination/$PROJ/`): the stream's opening entry (worktree facts, trunk branch, charter path), then every entry since — note `breaking`/`convention` entries not yet absorbed.

3. **Read the charter** (`docs/streams/<slug>-CHARTER.md` on this branch). If it doesn't exist yet, this is a charter-authoring session, not an implementation run: say so and invoke the **smallplans:stream-charter** skill instead. If it exists but its ratification block isn't `RATIFIED`, implementation hasn't been authorized — stop and say what's missing. Also read the project bindings (`docs/PARALLEL-DEV-WORKFLOW.md`) sections the run will need (migrations, isolation).

4. **Sync if triggered** (trunk moved: `git log --oneline HEAD..<trunk> | head`; or unabsorbed `breaking`/`convention` entries): invoke the **smallplans:stream-sync** skill NOW, before feature work. Starting current maximizes uninterrupted runtime.

5. **Locate progress and state the run plan.** Charter phase checkboxes + `git log --oneline <trunk>..HEAD` say where work stands. State in one short block: phases this run will execute (default: ALL remaining unblocked phases — steering may narrow this; context size never does), the envelope remaining, and any steering. Then go — do not wait for confirmation; ratification already happened.

## The run loop

- **Atomic green commits.** Small commits, suite-relevant tests green per commit, full suite at phase boundaries. The commit trail is the resume anchor — a run killed at any point resumes cleanly with `/smallplans:stream-work`.
- **Checkpoint at every commit and phase boundary** (cheap, seconds):
  ```bash
  ls ~/.claude/smallcoordination/$PROJ/ | tail -5
  git log --oneline HEAD..<trunk> | head -3
  ```
  React: new `breaking`/`convention` entry, or trunk landed migrations → finish the current task to a green commit, then invoke **smallplans:stream-sync** at that safe point, then continue. Trunk moved in minor ways → continue; sync no later than the next phase boundary.
- **Context checkpoint (context-kit).** Same cadence as the ledger checkpoint: run the context measurement in `~/.claude/context-kit/RECYCLING.md` and follow it — over the threshold → overwrite this worktree's rolling handoff (`ROLLING-HANDOFF.xml`); after any compaction → re-orient from disk per the hook-injected instructions, then continue the run. Context pressure is NEVER a run-end condition: do not wind down or end a run because the compaction threshold is near — refresh the handoff and work straight through the flush; surviving it is what the kit is for. If that file is missing, the kit was rolled back — skip this bullet.
- **Safe point** = clean tree + green suite. Never sync with a dirty tree. A sync ends green or the run stops there with honest status — never leave a red merge.
- **Stream-side only.** Never commit to, merge into, or push the trunk branch. Trunk-safe Rule-2 slices discovered mid-run (a seam, a mechanical rename) are **queued**: note them in the charter's follow-ups section and write a `heads-up` entry; an attended session lands them on trunk.
- **Migrations:** after any `makemigrations`, immediately `git mv` the generated file into the stream's `9xxx` namespace (first one: `9001_…`; bindings §3 is the spec). Never leave a trunk-numbered migration in the stream.
- **Dev servers for verification.** Start and stop the stream's own backend/frontend on its reserved ports at any time — inherent stream-private capability, no grant needed (bindings §2 has the commands; logs go to the worktree's `data/`). Verify against the stream's ports (curl, suite, browser tooling). Stop **by port only** (`kill $(lsof -ti tcp:<port>)`) — never by process name, which would kill trunk's servers. End the run with the servers it started stopped, unless steering says keep them up.
- **Ledger duties.** Anything shipped that passes the pertinence test → the **smallplans:coord-note** skill (it carries the format and the test). Entries are instant — no commit, no friction.
- **Spend governance.** Track app-level LLM spend against the charter envelope. Approaching the envelope → finish to a safe point and stop.
- **Subagents and ultracode.** Subagents inherit this worktree — correct and intended. Do **not** give DB-touching subagents `isolation: "worktree"`: a temporary worktree's directory name becomes a *different* DB suffix, pointing them at databases that don't exist. Read-only/non-DB agents may use it.

**Pre-authorized by the ratified charter (never ask mid-run):** spend up to the envelope; rebuilding/dropping the stream's own private DBs (`*_<slug>` only — the charter's explicit carve-out from the standing destructive-action rule); executing the phase plan including minor documented deviations.

**Hard stops — commit green, update charter progress, write status, end the turn:**
1. Envelope reached.
2. A sync conflict requiring a charter-level decision (trunk changed shared schema/behavior incompatibly with the stream's design).
3. A discovery that invalidates a charter assumption (structural deviation, not a minor one).
4. Anything outside pre-authorization: trunk writes, destructive ops beyond the stream-DB carve-out, scope changes.
5. A suite that cannot be brought green within the current task's scope.

## Run end

A run ends ONLY when one of these holds — nothing else is an exit:

1. **No unblocked work remains**: every charter phase is complete, or every remaining phase is gated on an attended action, a trunk landing, or a user decision.
2. **A hard stop fired** (the list above).
3. **Steering for this run set a stop time or narrower scope**, and it has been reached.

A phase boundary is a checkpoint, not an exit: finishing a phase means checkpoint, then continue into the next unblocked phase in the same run. Context pressure — approaching or undergoing compaction — is never a run-end condition (see the context checkpoint bullet). Precedent from earlier runs that happened to end at a phase boundary does not redefine this rule, and neither does ledger-entry phrasing about what a phase "unblocks."

Closeout, once one of the three conditions holds: 1. Full suite, honest result. 2. Charter progress section updated (phases checked, follow-ups queued, spend logged) and committed. 3. If the run produced facts other sessions need (a contract the trunk should expect, a queued slice), a closing entry via **smallplans:coord-note**. 4. Status message: what shipped, what's queued, WHICH end condition stopped the run, and that the next session is `/smallplans:stream-work` again. Landing is never started autonomously — that is `/smallplans:stream-land`, attended.
