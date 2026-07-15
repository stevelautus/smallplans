---
name: stream-land
description: >-
  Execute the attended landing of a stream into trunk: freeze announcement,
  final sync, migration renumbering (9xxx → next trunk numbers), fresh-clone
  rehearsal, the no-ff merge, trunk suite, working-DB migration via the
  project's backend-stop procedure, close-out entry, and permission-gated
  cleanup. Use when the user says "land the stream", "merge the feature back to
  trunk", "ship the stream". ATTENDED ONLY — the user must be present; never
  run this from an autonomous /smallplans:stream-work session.
---

# Stream Land

Landing should be boring: by the time it runs, the stream is current with trunk and holds only its irreducible core. This skill makes it boring by rehearsing the merge before performing it. The user is present throughout — two steps touch the real working corpus and several are destructive.

## Preconditions

- Invoked in the stream worktree, user attending. Charter phases complete, or the user explicitly accepts a partial landing.
- Suite green, tree clean. Trunk worktree not mid-merge/rebase.

## Procedure

1. **Announce the freeze** via `/smallplans:coord-note`, type `reservation`: "feat_<slug> landing in progress — trunk holds new migrations and new config keys until the `landed` entry." Hours, not days. If anything below fails in a way that needs real debugging: lift the freeze with a follow-up entry, fix in the stream, re-announce later. Never debug while trunk is frozen.
2. **Final sync** via `/smallplans:stream-sync`. Must end green.
3. **Renumber stream migrations** (spec: bindings doc §3):
   - Next free number N = max trunk migration number (post-sync).
   - `git mv` each `9xxx` migration to the next sequential trunk number in dependency-graph order; fix the `dependencies` strings inside the renamed set (each references its predecessor's old `9xxx` name).
   - Verify nothing dangles: `grep -rn "9[0-9]\{3\}_" <migrations-dir>/` must come back empty (see bindings for your project's migration directory path).
4. **Rehearse the merge result.** Build a fresh clone of trunk's working DB (the bindings' clone commands, new throwaway name), run the project's migrate command with the renumbered set against it, run the **full suite** against it. This is the step that makes step 6 uneventful. Failures here → see step 1's lift-the-freeze rule.
5. **Land:** from the MAIN checkout, `git -C <main-checkout> merge --no-ff feat_<slug>`; full suite on trunk; push per normal practice.
6. **Apply to the real working DB** — per the project's standing backend-stop procedure (see bindings doc). This touches the corpus: **get the user's explicit go immediately before.**
7. **Close out** via `/smallplans:coord-note`, type `heads-up`: "feat_<slug> landed @<sha> — freeze lifted." Note any contract-phase work now queued as ordinary trunk work.
8. **Cleanup.** First stop anything still listening on the stream's ports — `kill $(lsof -ti tcp:<api-port>) 2>/dev/null; kill $(lsof -ti tcp:<web-port>) 2>/dev/null` (by port, never by name; a server still running from the worktree would break its removal). Then, **each item only with the user's explicit go, named individually:** `git worktree remove <path>`, `git branch -d feat_<slug>`, drop the stream's private databases per bindings (e.g. `dropdb <stream-db-<slug>` for each env), drop the rehearsal clone from step 4. Skipping cleanup is fine; doing it silently is not.

## Rules

- Never autonomous, never rushed: each numbered step completes and verifies before the next starts.
- The freeze (step 1) is the one bounded exception to trunk's right-of-way — keep it short and always lift it explicitly, success or not.
- Merge only; the stream's history lands truthfully (`--no-ff`, no squash, no rebase).
