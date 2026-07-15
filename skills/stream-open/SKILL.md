---
name: stream-open
description: >-
  Open a parallel development stream: create the feature worktree and branch,
  build its isolated environment (venv, node_modules, private databases, ports),
  prove isolation with a green suite, and write the opening coordination-ledger
  entry. Use when the user says "open a stream", "set up the worktree for
  <feature>", "start the <slug> stream", or runs /smallplans:stream-open <slug>. Part of
  the parallel-dev workflow (~/.claude/smallcoordination/WORKFLOW.md); pairs with
  /smallplans:stream-work, which runs implementation sessions inside the stream.
---

# Stream Open

Mechanically establish a stream per the global protocol (`~/.claude/smallcoordination/WORKFLOW.md`) and the project's bindings doc (`docs/PARALLEL-DEV-WORKFLOW.md` in the repo). Opening creates things only — worktree, branch, venv, node_modules, private DBs, one ledger entry. It never deletes, never commits, never touches trunk state, so it runs without pauses once the slug is confirmed.

## What the user typed after the command

The first token after `/smallplans:stream-open` is the slug. Anything after it is steering (e.g. a different base branch). If no slug was given, ask for one — it is the single required input.

## Procedure

1. **Validate and derive.**
   - Slug must match `^[a-z][a-z0-9_]*$` and stay short (≤ ~20 chars) — it becomes a database-name suffix and a directory name. Reject and re-ask otherwise.
   - Derive the project key and main checkout:
     ```bash
     COMMON="$(git rev-parse --path-format=absolute --git-common-dir)"
     MAIN="$(dirname "$COMMON")"; PROJ="$(basename "$MAIN")"
     ```
   - Trunk = the branch currently checked out in the main checkout (`git -C "$MAIN" branch --show-current`), unless the user's steering names another.

2. **Preconditions — stop with specific guidance if any fail; do not improvise around them.**
   - The repo has a bindings doc at `docs/PARALLEL-DEV-WORKFLOW.md`. Missing → the project hasn't adopted the workflow; point at `~/.claude/smallcoordination/WORKFLOW.md` §11 and stop.
   - The bindings doc's adoption section lists enabling changes — verify they are actually present in the codebase. Absent → adoption is pending ratification; opening a stream now would share trunk's databases. Stop.
   - Target worktree path free, branch name `feat_<slug>` unused, no existing ledger entries claiming the slug (`ls ~/.claude/smallcoordination/$PROJ/ 2>/dev/null | grep <slug>`).
   - Database privileges and resources suffice per your project's configuration. Consult the bindings doc for project-specific setup requirements. A mismatch means the machine is missing setup described in the bindings' privilege note — stop and say so.
   - Pick the port pair: next free per the bindings (first stream takes the second pair, e.g. 8001/3001), and verify it is actually free — `lsof -ti tcp:8001 -ti tcp:3001` must return nothing. If that pair needs an allowlist change (CORS) that hasn't landed, say so — it blocks the frontend, not the opening. The pair becomes the stream's reserved property: its sessions start/stop their own servers on it; nothing else does.

3. **Execute the bindings doc's stream-opening checklist, step by step, verifying each.** The bindings doc specifies: worktree add from trunk tip; environment build (venv, node_modules, etc. — recreate the environment per the project's bindings doc); private dev-DB clone if applicable; configuration file setup with stream-specific settings (ports, database names). Use the bindings' exact commands; they are the project's source of truth, this skill is just the executor.

4. **Prove isolation before declaring success.** From the stream worktree, run the suite. Green is the proof that the stream runs without touching trunk state. Red → diagnose (almost always an environment step that silently failed); do not write the opening entry until green.

5. **Write the opening ledger entry** via the **smallplans:coord-note** skill (type `heads-up`), recording the facts later sessions will parse: worktree path, branch, trunk branch at open (with sha), port pair (if applicable), private database names (if applicable), reserved modules (if the user named any; otherwise "TBD at charter"), and the charter path: `docs/streams/<slug>-CHARTER.md` — "to be authored".

6. **Report and hand off.** State what was created (paths, branch, databases, ports, suite result) and the next two lifecycle steps verbatim:
   - `/smallplans:stream-charter` in the new worktree — scaffolds the plan doc with the required ratification block and walks ratification.
   - then `/smallplans:stream-work` for implementation runs.

   Do not start the charter or any feature work yourself unless the user asks.

## Conventions to honor

- **Create, never destroy.** If something half-exists from a failed prior attempt (a worktree without a venv, a database without a worktree), report exactly what exists and let the user decide; cleanup is destructive and needs their explicit go. Sole carve-out: environment setup steps that are idempotent by design (like venv recreation) — use the bindings doc's recipes.
- The opening entry is the stream's machine-readable anchor — `/smallplans:stream-work` reads it. Keep its facts exact.
- Everything runs from absolute paths; the skill works the same whether invoked from the main checkout or elsewhere.
