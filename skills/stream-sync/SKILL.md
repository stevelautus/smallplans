---
name: stream-sync
description: >-
  Safely merge the trunk branch into the current stream worktree: safe-point
  precondition, the merge, Django migration-graph re-pointing, conflict
  resolution posture, and the suite-green gate. Use in a stream worktree when
  trunk has moved, when a breaking/convention ledger entry landed, before
  landing, at /smallplans:stream-work safe points, or when the user says "sync the
  stream", "pull trunk in", "merge trunk into the feature branch". Merge only —
  never rebase.
---

# Stream Sync

One sync = one merge of trunk into the stream, finished green. Conflicts are resolved here, stream-side, with both sides' intent on record — never by a trunk session, never later.

## Procedure

1. **Safe point check.** Must be in a stream worktree (`git rev-parse --git-dir` ≠ `--git-common-dir`) with a **clean tree**. Dirty → stop: finish the current task to a green commit first, then re-invoke. Never sync a dirty tree.
2. **Identify trunk and the incoming delta.** Trunk = the branch named in the stream's opening ledger entry (fallback: the main checkout's current branch). Show what's coming:
   ```bash
   git log --oneline HEAD..<trunk> | head -20
   git diff --name-only HEAD...<trunk>
   ```
   Nothing incoming → report "already current" and stop.
3. **Merge:** `git merge <trunk>` with message `sync <trunk> @<short-sha>`.
4. **Conflicts** (if any): resolve here. Default posture: **take trunk's structure, re-apply the stream's intent on top.** Intent sources: the ledger, `git log <trunk> -- <file>`, the stream's charter. Never resolve by discarding a trunk change silently. A resolution gnarly enough to surprise a later session → `/smallplans:coord-note` heads-up after the sync completes.
5. **Migrations, if trunk brought any** (the project bindings doc, `docs/PARALLEL-DEV-WORKFLOW.md` §3, is the spec):
   - Symptom of the known state: the ORM refuses with "multiple leaf nodes" — trunk's new migration and the stream's first namespaced migration both descend from the old head.
   - Fix: edit the **first** namespaced migration's `dependencies` to point at the new trunk head, then run the project's migration command against the stream's private DB (the ORM tracks the applied set by name, not order, so the new trunk migration applies fine after the already-applied namespaced one).
   - If migration fails because both sides touched the same tables incompatibly: that is a real schema conflict, not tooling. Reconcile the namespaced migration content; if the private DB is wedged, rebuild it from a fresh trunk clone per the bindings and re-apply.
6. **Green gate.** The sync is not done until the suite is green in this worktree — full suite if schema, shared contracts, or config moved; targeted otherwise. Never leave a red merge for the next session: fix forward now, or if genuinely stuck, commit nothing further, write an honest `/smallplans:coord-note` heads-up, and surface to the user.
7. **Report:** commits absorbed, conflicts resolved (and how), migration re-points made, suite result.

## Rules

- Merge only. No rebase, no force-push, no history rewrite — ever.
- Stream-side only: this skill never writes to trunk.
- Frequency guidance lives with the caller (/smallplans:stream-work checkpoints, the parallel-dev rule); this skill executes one sync correctly.
