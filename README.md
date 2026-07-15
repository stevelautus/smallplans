# smallplans

**Plan → ratify → autonomous build.**

A Claude Code plugin that packages planning-and-execution for feature development: author a plan doc, ratify it to authorize autonomous work, then run multi-hour uninterrupted builds (on trunk or in parallel worktree streams coordinated by a machine-global ledger).

## What you need

- A git repository with a GitHub remote
- `gh` authenticated (for `/implement-plan`'s PR closeout)
- For streams: git worktrees + a per-project bindings doc (see [adoption](#adoption))

## Install

### From the plugin marketplace (recommended)

```bash
claude plugin install stevelautus/smallplans
```

Then enable it in your project or globally:

```bash
# Per-project (recommended where plan-doc culture applies)
cd your-repo
claude settings --add enabledPlugins.smallplans@smallplans true

# Or user-wide
claude settings --scope=user --add enabledPlugins.smallplans@smallplans true
```

### From a local checkout

Clone this repo, then:

```bash
# Register the checkout as a directory-source marketplace
cd ~/.claude/settings
# Edit settings.json or settings.local.json:
# "extraKnownMarketplaces": {
#   "smallplans": {
#     "source": {
#       "source": "directory",
#       "path": "/path/to/smallplans-clone"
#     }
#   }
# }

# Then enable the plugin per-project or user-wide (see above)
```

### Update

```bash
claude plugin update smallplans@smallplans
```

**That's it.** No further setup — data directories are created on demand, the hook activates with the plugin.

## Quick reference

All commands are invoked as `/smallplans:<name>`.

### Trunk-based development

| Command | Purpose | When to use |
|---------|---------|-----------|
| `/smallplans:plan-feature` | Author a feature plan (ratifiable) | Starting a new feature; when you know what needs to build and who'll build it |
| `/smallplans:implement-plan` | Execute a ratified plan autonomously (usually ultracode) | After the plan is ratified; creates a branch, runs to completion, opens a PR |

### Parallel streams (worktree-based)

| Command | Purpose | When to use |
|---------|---------|-----------|
| `/smallplans:stream-open` | Create a parallel-dev worktree + isolated environment | Starting work that would leave trunk broken between sessions |
| `/smallplans:stream-charter` | Author the stream's plan + ratification | After opening a stream; defines phases, reserved modules, spend, pre-authorizations |
| `/smallplans:stream-work` | Autonomous implementation inside the stream (resumable) | After charter ratification; multi-hour uninterrupted runs |
| `/smallplans:stream-sync` | Safely merge trunk into the stream worktree | When trunk moves; checkpoints during stream work; before landing |
| `/smallplans:stream-land` | Attended landing of stream back into trunk | After all stream work is complete; user present for every step |

### Coordination (any session)

| Command | Purpose | When to use |
|---------|---------|-----------|
| `/smallplans:coord-check` | Read standing obligations from the ledger | At session start when the project has active streams or breaking changes |
| `/smallplans:coord-note` | Write a ledger entry | After shipping anything others need to know about (seams, breaking changes, freezes) |

**Start here:**
- **Trunk feature:** `/smallplans:plan-feature`
- **Stream:** `/smallplans:stream-open`, then follow prompts

## What runs automatically

The plugin registers **one** automatic behavior (a SessionStart hook):

**On every session start:**
1. Refreshes `~/.claude/smallcoordination/WORKFLOW.md` from the bundled copy (if `~/.claude/smallcoordination/` already exists)
2. Checks `~/.claude/smallcoordination/<project>/` for the current project — if entries exist, injects an obligation to run `/smallplans:coord-check` and reminds you of the merge-only rule (sync = merge, never rebase or force-push a branch another session has seen)

**What gets written to HOME:**
- `~/.claude/smallcoordination/` — the machine-global coordination ledger (one file per entry, created on first use)
- `~/.claude/smallcoordination/WORKFLOW.md` — auto-materialized stable copy of the protocol docs (refreshed at session start if ledger dir exists)

**This data survives uninstall.** To remove everything:
```bash
# Disable the plugin
claude settings --scope=user --remove enabledPlugins.smallplans@smallplans

# Delete the ledger (optional; entries are permanent machine metadata)
rm -rf ~/.claude/smallcoordination/
```

## Adoption

### Trunk only (no streams)

**Nothing beyond the install + enable steps above.** Plan docs conventionally live in `docs/`, and plans are ratified in conversation before `/implement-plan` runs.

```bash
# Example: create a feature plan in docs/
/smallplans:plan-feature Add user profiles v1
# Interview → plan doc at docs/add-user-profiles-v1-PLAN.md
# You ratify it in chat
# In a fresh session: /implement-plan docs/add-user-profiles-v1-PLAN.md
```

### Optional: document your plan-doc culture

Add a pointer section to your project's `CLAUDE.md`:

```markdown
## Planning workflow (smallplans plugin)

Plans live in `docs/` and follow the ratification model (see `/smallplans:plan-feature`).
Key decisions (scope, phases, pre-authorizations) are made at plan time via the ratified document,
not re-litigated mid-implementation. See the plugin README for details.
```

### Streams (parallel development)

Required: write a per-project bindings document at `docs/PARALLEL-DEV-WORKFLOW.md`.

The bindings doc answers, with concrete commands:

1. **Databases** — how each worktree gets private DB names, how to clone a working DB at stream-open
2. **Ports** — the port pair reserved per stream, any allowlists (CORS, etc.) that must know about it
3. **Dependencies** — per-worktree build steps (venv, node_modules, etc.)
4. **Data directories** — paths that must resolve inside the worktree
5. **Shared-with-no-isolation list** — what streams share (DB server, API keys, spend)

Example stub (Django + PostgreSQL):

```markdown
# PARALLEL-DEV-WORKFLOW Bindings — MyProject

## Database isolation

Stream worktrees use `<project>_dev_<slug>` and `<project>_test_<slug>` (e.g., `myproject_dev_auth_redesign`).

Clone command: `createdb -T myproject_dev myproject_dev_<slug>`

## Ports

Stream ports: API on `800<N>`, web on `300<N>` (where N = the stream number). Trunk: 8000, 3000.

## Dependencies

```bash
# In the stream worktree
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Migrations

Trunk owns `00NN`; stream renames generated migrations to `9xxx` (first = `9001_`).
Re-point: edit the first `9xxx` migration's `dependencies` field to reference the new trunk head.
```

Also add an optional pointer to your project's `CLAUDE.md`:

```markdown
## Parallel streams (smallplans plugin)

See `docs/PARALLEL-DEV-WORKFLOW.md` for environment isolation and bindings.
Streams are for work that would leave trunk broken or half-true between sessions.
See `/smallplans:stream-open` for the full lifecycle.
```

## Walkthrough

### Trunk feature, end to end

```bash
# 1. Author a plan
/smallplans:plan-feature Onboard OAuth (interactive → docs/onboard-oauth-PLAN.md)

# You review and ratify the plan in chat:
# "Ratify the plan" → plan status becomes RATIFIED

# 2. In a fresh session (often ultracode), implement it
/smallplans:implement-plan docs/onboard-oauth-PLAN.md
# Bootstrap: checks ratification, fresh branch, initial commit
# Run loop: phases execute, atomic commits, context checkpoints
# Closeout: pushes branch, opens PR into main, reports URL

# 3. Review and merge the PR on GitHub
```

### Stream, end to end

```bash
# 1. Open a stream (user supplies slug + port pair)
/smallplans:stream-open multitenant
# Creates worktree feat_multitenant, isolated environment, private DBs, green suite

# 2. Author the stream's plan (charter)
/smallplans:stream-charter
# Interactive → docs/streams/multitenant-CHARTER.md with ratification block

# You ratify the charter in chat:
# "Ratify the charter" → status becomes RATIFIED

# 3. Work the stream (usually ultracode, resumable)
/smallplans:stream-work
# Bootstrap: reads charter, syncs if trunk moved, states run plan
# Run loop: atomic commits, ledger checkpoints, syncs at safe points
# Closeout: updates charter progress, reports work queued

# 4. If trunk moves mid-stream (checkpoint alerts you)
/smallplans:stream-sync
# Merges trunk into worktree, re-points migrations, runs suite

# 5. When complete, land the stream (attended, user present)
/smallplans:stream-land
# Freeze announcement, final sync, renumber migrations, rehearsal,
# no-ff merge, suite, apply to working DB, cleanup

# 6. Any trunk-safe slices the stream discovered → land separately as ordinary trunk work
```

### Ledger entries

When should you write one? **The pertinence test:** would a session doing *unrelated* work need to act differently?

**Examples:**

```bash
# A refactor stream lands a seam (new code uses it immediately)
/smallplans:coord-note
# type: convention
# "New code accesses user via get_current_user(), never a literal"

# A breaking schema change ships on trunk
/smallplans:coord-note
# type: breaking
# "User.avatar is now a File, not a URL; streams must adapt"

# A stream is landing; trunk should hold migrations
/smallplans:coord-note
# type: reservation
# "feat_multitenant landing — trunk holds new migrations until landed entry"
```

## Concepts

See [`docs/WORKFLOW.md`](docs/WORKFLOW.md) for the protocol's rationale and contracts:
- The three rules (trunk has right-of-way, work lands where it belongs, merge-only)
- How seam-first refactors (expand / build / contract) minimize end-merge conflicts
- Ledger semantics and the pertinence test
- Why rebase-based syncing breaks parallel work

## Troubleshooting

### `coords-check` says "no project key derived" or "ledger not found"

**Likely cause:** you're not in a git repo, or the project hasn't created any ledger entries yet.

**Fix:** 
- For non-git cwd: switch to a git repo.
- For first stream setup: the first `/smallplans:stream-open` or `/smallplans:coord-note` creates the ledger directory.

### Conflicting ledger entries (two sessions wrote at once)

**Won't happen.** The ledger uses per-file names to make concurrent writers safe. If two entries were written in the same minute, rename one (append `_1` to its filename) — they're still append-only.

### The hook isn't running

**Check:**
```bash
claude plugin list | grep smallplans
# Should show: smallplans (enabled locally or globally)

# Fresh session with debugging
claude --debug
# Look for SessionStart hook execution in logs
```

**If you're in a non-git directory:** the hook skips (by design — no project key to derive).

### Uninstall

```bash
# Remove the plugin
claude plugin uninstall smallplans@smallplans

# (Optional) Clean up the ledger
rm -rf ~/.claude/smallcoordination/
```

The ledger is intentionally left behind (permanent machine metadata); you decide whether to keep it.

## Relationship to smallcontext

`smallcontext` is an optional sibling plugin (compaction continuity, rolling handoff materialization). They work independently:

- **smallplans without smallcontext:** works as-is; context-kit checkpoints gracefully skip if the kit is rolled back
- **smallcontext without smallplans:** also works; no coupling
- **Both together:** they share the HOME harness and coordinate via machine-local paths — no conflicts

## License

Apache License 2.0 — see [`LICENSE`](LICENSE) for terms.

---

**Questions or issues?** See the plugin README or the protocol docs at `docs/WORKFLOW.md`.
