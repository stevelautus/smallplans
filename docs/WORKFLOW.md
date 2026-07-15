# Parallel Development Workflow — Worktree Streams Beside a Moving Trunk

**Scope: global.** This protocol applies to any project on this machine. Each adopting project documents its own bindings (databases, ports, migration mechanics, setup) in-repo at `docs/PARALLEL-DEV-WORKFLOW.md`. This file owns the protocol; bindings docs own the project specifics; the skills own the procedures. **Human walkthrough with example commands: the walkthrough section of the plugin's `README.md`.** Assumption baked in throughout: all worktrees and all sessions live on **one machine, one HOME** — the smallcoordination ledger directory is the shared bus.

---

## 1. Purpose

The default flow for a project is: everything lands on the trunk (the active integration branch), built by multiple sequential and sometimes parallel sessions. That flow stays. A **stream** is the second shape, for work too disruptive to build in trunk-sized increments: a feature branch in its own git worktree, developed by its own sessions over days or weeks while trunk keeps moving.

Failure modes this protocol exists to prevent, in severity order:

1. **Shared-state corruption** — two worktrees with divergent schemas pointing at the same database.
2. **Generated-artifact collisions** — both sides minting the same migration number.
3. **Semantic drift** — trunk renames a model or changes behavior; the stream builds for weeks against the old world and learns at merge time.
4. **The end-of-life mega-rebase** — a thousand-line conflict resolved in one sitting with no memory of either side's intent.

What "avoiding the rebase headache altogether" honestly means: **no rebase is ever performed** (sync and landing are ordinary merges), classes 1–2 are eliminated structurally, class 3 is caught early by the coordination ledger, and class 4 is dissolved into small sync-time installments resolved with both sides' intent on record.

**When NOT to open a stream:** if the work slices into trunk-safe increments, build it on trunk (see Rule 2 — for refactors, see §3 before concluding it doesn't slice). Streams are for work that would leave trunk broken or half-true between sessions. Run **at most one major stream per project** at a time; the scheme generalizes pairwise but coordination cost compounds.

## 2. Topology and the three rules

- **Trunk** = the project's active integration branch in its main checkout. A stream = branch `feat_<slug>` cut from trunk tip, checked out as a linked worktree (project bindings say where). If trunk rolls over mid-stream (version branch ships, next one cut), the stream's sync target becomes the new branch; nothing else changes.
- Worktree mechanics worth knowing: all worktrees share one object store and one ref namespace, so from the stream `git log <trunk>` is always current with zero setup. The same branch cannot be checked out twice. `git worktree list` is how any session discovers what exists.
- Stream branches may be pushed for backup; never force-pushed.

**Rule 1 — Trunk has right-of-way.** Trunk never waits for, adapts to, or resolves conflicts for the stream. The stream absorbs trunk. Exactly two bounded exceptions: modules the stream has reserved via the ledger, and the landing freeze (§8).

**Rule 2 — Work lands where it belongs.** Work that is trunk-safe — leaves trunk's behavior identical, suite green, no half-states — lands **on trunk**, even when the stream motivates it, and regardless of which actor executes it (a stream session may do it on a short-lived branch cut from trunk tip and merged within a day or two; what's forbidden is parking trunk-safe work inside the stream). The stream holds only what cannot land behavior-neutrally. This continuously drains the stream to its irreducible core, and for refactor-shaped work it does most of the heavy lifting — see §3.

**Rule 3 — Merge-only.** No rebase, no force-push, no history rewrite on any branch more than one session has seen. Sync = merge trunk into stream (§5). Landing = merge stream into trunk (§8). Both are ordinary, truthful merge commits.

**Stream lifecycle** — each step is a skill; **the skills own the procedures, this doc owns the contracts**:

1. **Open** — `/smallplans:stream-open <slug>`: worktree, branch, isolated environment, private DBs, green-suite isolation proof, opening ledger entry. Creates only; needs nothing beyond the user's go on the slug.
2. **Charter** — `/smallplans:stream-charter`: authors `docs/streams/<slug>-CHARTER.md` on the stream branch with the required ratification block (scope-rule amendments, the §3 seam plan, reserved modules, phase plan, spend envelope, §9 pre-authorizations), then walks live ratification. **Ratification is what authorizes implementation.** Written for a cold reader — stream sessions have no path-keyed memory.
3. **Implement** — `/smallplans:stream-work`: autonomous multi-hour runs under §9, syncing via `/smallplans:stream-sync` as they go.
4. **Land** — `/smallplans:stream-land`: attended, §8. Never started autonomously.
5. **Contract** — shim removal and tightening proceed as ordinary trunk work.

## 3. Refactor-shaped streams: seam-first (expand / build / contract)

The hard case: the feature is really a **cross-cutting refactor** of core modules (multi-tenancy, a storage swap, an auth layer). The naive split fails in both directions — keep it all in the stream and you rewrite the same core files trunk edits daily (maximum conflict surface, maximum drift); push it onto trunk and trunk carries half-built behavior. The resolution is branch-by-abstraction, run in three moves:

1. **EXPAND (on trunk, via Rule 2).** Land the *seams* first: abstraction points whose default implementation preserves today's behavior exactly. Context/identity accessors that resolve to today's single fixed answer, provider interfaces that read today's config, new tables and nullable-or-defaulted columns that nothing requires yet, framework-level dependency injection replacing per-callsite assumptions. Each seam is small, behavior-neutral, suite-green, landed at normal trunk cadence with a ledger `convention` entry.
2. **BUILD (in the stream).** The genuinely disruptive half — new behavior, new UI, new lifecycles — written against the seams, in new modules wherever possible.
3. **CONTRACT (at landing and immediately after).** Flip the seam defaults to the new implementation, remove the single-mode shims, tighten constraints (the NOT NULLs, the uniqueness rules). Contract-phase schema changes often land as ordinary trunk migrations right after the merge.

Why this minimizes the disruptive end-merge: **every landed seam converts a future divergent-edit surface into a shared interface.** Trunk sessions write new work *against* the seam from the day it lands (that's what the `convention` entry instructs), so ongoing trunk development **converges toward the stream instead of drifting away from it** — the property that protects the stream from trunk as much as trunk from the stream. The stream's diff trends toward new modules (which merge trivially) plus a small cutover.

**Costs, stated plainly:** seams must be designed before the feature is built (make it the stream charter's phase 0), and trunk carries temporary indirection until contract. Both are bounded, and they are the price of a no-rebase parallel refactor.

**Guardrails:**
- A seam may land on trunk **only while a ratified stream consumes it immediately.** Without that, it is exactly the speculative abstraction most project scope rules (correctly) forbid. The ratified charter is what converts speculation into enabling work — and if the project's standing scope rules would reject the seam (e.g. "no auth in V1"), the charter ratification must consciously amend those rules, not quietly contradict them.
- If the suite can tell the difference after a Rule-2 slice, it wasn't a seam — it was the feature. Pull it back into the stream.
- **Mass mechanical churn** (renames, signature threading, import moves) is the classic conflict generator. It lands trunk-side as its own announced slice (`breaking` ledger entry, executed in hours), never sits in a stream diff for weeks. Prefer shapes that minimize touched lines: a context object over N-parameter threading, framework-level injection over per-callsite edits.
- Module reservations stay **narrow** for refactor streams: reserve the new modules the stream owns outright; do not try to reserve core shared files. Protection for those comes from seams plus sync frequency (§5), not from fencing trunk out of its own core (Rule 1).

## 4. The coordination ledger

The central place sessions record what other sessions need to know. It is **not** a diary, a changelog, or a handoff doc (handoffs remain a separate mechanism with separate rules). It is a bulletin board of facts that change what *another* session must do — readable and writable instantly by every session in every worktree of every project, because it lives in HOME, outside any repo.

- **Location:** `~/.claude/smallcoordination/<project>/`, one file per entry, **append-only**. Never edit a committed entry; a correction is a new entry. No index file (chronological filenames make one unnecessary).
- **Project key** = the main checkout's directory name. Derive from anywhere, including a worktree:
  `basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`
  (For a checkout at `~/code/myproject`: `myproject`.) Create the directory on first use.
- **The pertinence test (the only admission rule):** *would a session doing unrelated work need to act differently after this?* If no, the commit message is the record — write nothing. A healthy ledger gets a handful of entries per week, not per session.
- **Types** (one per entry): `reservation` (claims: module ownership, landing freezes, planned rename waves) · `breaking` (shipped changes others must adapt to) · `convention` (new rules effective immediately, including landed seams) · `heads-up` (lifecycle events, spend, surprises). **`/smallplans:coord-note` owns the operational detail**: full type definitions with examples, the entry format, the filename convention, and what always qualifies.
- **Reading is a skill too:** `/smallplans:coord-check` at session start reads the ledger and distills standing obligations (freezes, reservations, seams, breaking changes). No git transport, no sync lag, no branch propagation — every entry is visible to every session the moment it's written.
- **Retention:** entries are tiny; keep them. After a stream lands, its entries may be moved to `<project>/archive/` — file moves are destructive, so only with the user's explicit go.
- **Limits to know:** the ledger is machine-local (it does not travel with a clone) and invisible to collaborators on other machines. For the single-machine multi-session model this protocol assumes, that is exactly right; if the model ever changes, revisit transport, not the protocol.

## 5. Sync protocol (trunk → stream)

Sync early, sync small. Each sync is a merge of trunk into the stream, resolved by a session with both sides' intent in front of it. For refactor-shaped streams, default to syncing **every working session**.

**Triggers — sync when any of these holds:**
1. Stream session start and `git log --oneline HEAD..<trunk> | head` is non-empty.
2. A new ledger entry of type `breaking` or `convention` from trunk.
3. You are about to modify a file trunk has touched since the last sync — check overlap first with `git diff --name-only HEAD...<trunk>`.
4. Trunk has moved and ~2 working days have passed since the last sync.
5. Always, immediately before landing.

**`/smallplans:stream-sync` owns the procedure** — one invocation = one merge, finished green. The contracts it enforces: conflicts are resolved in the stream worktree only (Rule 1), with the default posture *take trunk's structure, re-apply the stream's intent*; trunk-delivered migrations get the project's graph re-point step before anything touches the stream DB; a sync is not done until the suite is green — never leave a red merge for the next session; gnarly resolutions get a `heads-up` entry; never rebase.

## 6. Parallel generated artifacts (migrations and their kin)

Generic requirement: anything with a **global ordered namespace** generated on both sides (migration numbers, sequence-numbered fixtures) must use a collision-free temporary namespace in the stream, renumbered once, mechanically, at landing. Trunk's sequence stays unconstrained (Rule 1) — no reserved blocks, nothing for trunk sessions to remember.

Django pattern (most projects here are Django-ORM): trunk owns `00NN`; the stream renames each generated migration into a `9xxx` namespace immediately (Django orders by the `dependencies` graph, not filenames, so high numbers interleave soundly); each sync that brings trunk migrations needs the first `9xxx` dependency re-pointed at the new trunk head; landing renumbers `9xxx →` next free `00NN` and verifies with a grep. Full mechanics live in the project bindings. Note that under seam-first (§3) most schema lands trunk-side as ordinary migrations, and the `9xxx` set trends toward empty — it remains the safety net, not the default path.

## 7. Isolation requirements (what a project's bindings must answer)

A stream must be able to run, migrate, and test **without touching trunk's runtime state**. The bindings doc for each project must answer, concretely, with commands:

1. **Database(s):** how each worktree gets private DB names automatically (no per-branch config edits that could leak into a landing), and how the stream's working DB is cloned at open.
2. **Ports / endpoints:** the port pairing per stream, and whatever allowlists (CORS etc.) must know about it.
3. **Dependencies:** per-worktree virtualenv / node_modules build steps.
4. **Data directories:** confirm runtime paths resolve inside the worktree.
5. **Shared-with-no-isolation list:** what streams still share (the database server, API keys and rate limits, monthly spend) and how visibility works.

Also bind: **session memory is path-keyed**, so stream sessions start memory-cold. The ledger (HOME-keyed, path-independent) and the stream's committed charter are the canonical shared memory; write charters for a cold reader.

## 8. Landing protocol

Landing should be boring: by Rule 2 and §3 the stream holds only its irreducible core, and by §5 it is already current. **`/smallplans:stream-land` owns the procedure** (freeze → final sync → renumber → fresh-clone rehearsal → no-ff merge → trunk suite → working-DB apply → close-out → cleanup), executed **attended** — the user present throughout. The contracts it enforces:

- The freeze is the one bounded exception to Rule 1: announced via a `reservation` entry, held for hours not days, always lifted explicitly. Never debug while trunk is frozen — lift, fix in the stream, re-announce.
- The merge is rehearsed against a fresh clone of trunk's working DB before it happens for real.
- Applying migrations to the real working DB, and every cleanup step (worktree, branch, the stream's DBs), require the user's explicit go, named individually.
- Landing is never started from an autonomous run; `/smallplans:stream-work` ends and recommends it instead.
- **Contract phase** (refactor streams): shim removal and constraint tightening proceed afterward as ordinary trunk work.

## 9. Autonomous long-run implementation sessions

The priority case: a multi-hour, uninterrupted, maximally autonomous session (often ultracode) implementing the charter inside the stream. The design principle: **everything askable is settled at charter ratification; everything else is a defined hard stop.** A run ends because the work is done, the envelope is spent, or a hard stop fired — never because the session needed permission.

**`/smallplans:stream-work` owns the procedure**: bootstrap (orient from ledger + charter, sync first if triggered, locate progress, go without waiting), the run loop (atomic green commits, a seconds-cheap coordination checkpoint at every commit, syncs via `/smallplans:stream-sync` only at safe points, `9xxx` migration discipline, ledger duties via `/smallplans:coord-note`, spend metering, the subagent worktree-isolation caveat), and run-end closeout. Runs are resumable from any interruption point — invoking `/smallplans:stream-work` again is idempotent. This section owns the contracts:

**Pre-authorized by the ratified charter (never ask mid-run):** spend up to the envelope; rebuilding/dropping the stream's own private `*_<slug>` DBs (an explicit, narrowly scoped carve-out from the standing destructive-action rule — granted by ratification, never assumed); executing the phase plan including minor documented deviations.

**Hard stops** (commit green, update charter progress, write status, end the turn): envelope reached · a sync conflict requiring a charter-level decision · a discovery that invalidates a charter assumption · anything outside pre-authorization (trunk writes, destructive ops beyond the carve-out, scope changes) · a suite that cannot be brought green within the current task's scope.

**Stream-side only:** autonomous runs never write to trunk — no commits, merges, or pushes to it. Rule-2 slices they discover are queued (charter follow-ups + `heads-up` entry) for attended sessions to land.

**Stream-port server lifecycle is inherently in-bounds:** runs start and stop the stream's own dev servers on its reserved ports freely for verification — no charter grant needed, nothing shared is touched. The discipline that makes it safe: target processes **by port, never by name** (name-targeting reaches trunk's servers); a stream never touches trunk's ports, and a trunk session never touches a stream's.

## 10. Obligations per actor (cheap by design)

**Every trunk session, only while a stream is open:**
- Session start: `/smallplans:coord-check`; honor what it reports (freezes, reservations, seams to build against).
- Shipping anything cross-cutting: `/smallplans:coord-note` (it applies the pertinence test for you).
- Don't restructure stream-reserved modules; a restructure is negotiated via a new ledger entry.

**Every stream session:**
- `/smallplans:stream-work` for implementation; `/smallplans:stream-sync` for any ad-hoc sync; `/smallplans:coord-note` for anything trunk must honor.
- Generated artifacts only in the temporary namespace. Never rebase. A sync ends green or the session isn't done.

**The user:**
- Gives the go on stream opening (cheap: a slug and a port pair), then **ratifies the charter** — the act that authorizes autonomous implementation, covering scope-rule amendments, the seam plan, reserved modules, the phase plan, the spend envelope, and the §9 pre-authorizations.
- Approves landing (it touches the working corpus) and all destructive cleanup; lands or delegates the Rule-2 slices that autonomous runs queue.
- Arbitrates the rare ownership dispute. Default ruling is Rule 1.

## 11. Adopting this protocol in a project

1. Write the bindings doc at `docs/PARALLEL-DEV-WORKFLOW.md` in the repo, answering §7 with commands, plus the project's migration mechanics (§6) and a stream-opening checklist. Land whatever small enabling patch the DB-isolation answer requires.
2. Add a short pointer section to the project's `CLAUDE.md` (this protocol + the bindings + the ledger location).
3. The plugin's gate hook handles session wiring everywhere, and the lifecycle skills (`/smallplans:stream-open`, `/smallplans:stream-work`) are likewise global — they read the project's bindings doc for the specifics. Beyond the bindings doc and its enabling patch, projects need nothing.

Adoption is deliberately doc-driven rather than a skill: it is a once-per-project design exercise (answering §7 against the project's real infrastructure), not a repeatable procedure. Skill-ify only if a second adoption proves clunky.

## 12. Design notes — alternatives rejected

- **Rebase-based syncing:** rewrites history multiple sessions have built on; re-litigates the same conflicts repeatedly. Merge-only resolves each conflict exactly once.
- **Pure trunk-based development (feature flags everywhere):** §3 deliberately captures its good half. As the *general* mechanism it puts trunk in prolonged half-states and requires flag infrastructure most of these projects rightly don't carry.
- **In-repo ledger (`docs/coordination/`):** versioned with the code, but entries then need git transport — branch-propagation lag, double-commits for stream→trunk visibility, cross-worktree `commit --only` machinery — and the protocol becomes per-project by construction. The HOME ledger is instant, transport-free, global, and matches the handoff-mechanism precedent for session infrastructure that doesn't belong in repo history. The cost (machine-local, not versioned with code) is correct for what it is: operational signaling, not documentation.
- **One ledger file:** concurrent-writer conflicts; per-entry files never conflict.
- **Per-checkout-path ledger keying** (the handoff scheme): would split a project's ledger across its worktrees — the opposite of the point. Keyed by main-checkout name instead, derivable from any worktree via `--git-common-dir`.
- **Reserved migration-number blocks:** a standing cognitive tax on every trunk session, backwards under Rule 1.
- **Broad module reservations for refactor streams:** fences trunk out of its own core for weeks; seams + sync frequency protect better and converge the branches instead of separating them.

## 13. Quick reference

Lifecycle skills: `/smallplans:stream-open <slug>` → `/smallplans:stream-charter` (ratification authorizes implementation) → `/smallplans:stream-work` autonomous runs → `/smallplans:stream-land` attended → contract on trunk.
Coordination skills, any session: `/smallplans:coord-check` at session start when the project's ledger has entries · `/smallplans:coord-note` after shipping anything cross-cutting · `/smallplans:stream-sync` to pull trunk into a stream.

```bash
PROJ=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
ls ~/.claude/smallcoordination/$PROJ/   # entries? → the protocol is active
git worktree list                       # what streams exist?
```

Rules: trunk has right-of-way · work lands where it belongs · merge-only, never rebase.
Refactor streams: seams land on trunk first (expand) · stream builds against them · landing contracts the shims.
