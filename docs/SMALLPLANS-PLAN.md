# smallplans — Plugin Build: Plan

**Status:** see Ratification block (§10) · **Author:** /plan-feature session with Steve, 2026-07-15
**Requirements source:** `/Users/ssmall/personal_code/occupal/docs/2026-07-15-claude-tooling-plugin-research.md` (read-only; "the research doc"). Where that doc and live source files disagree, live files win — flag the discrepancy, follow neither silently.

## 0. How to use this document

This plan is executed by `/implement-plan docs/SMALLPLANS-PLAN.md` in a fresh session. It is written for a cold reader: everything operationally needed is in here or at the absolute paths named in here. Progress lives in the §4 checkboxes plus the commit trail; re-running the command resumes from them. The research doc is background and arbitration, not required reading order.

## 1. Goal and scope

**Goal.** Turn this repo into an installable, public, open-source Claude Code plugin named `smallplans` that packages the planning-and-execution paradigm currently living in nine user-level skills on this machine: plan → ratify → autonomous build, in two variations (directly on trunk; farmed out to worktree streams coordinated through a machine-global ledger).

**Ships:**
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — single-plugin repo doubling as its own marketplace.
- `skills/<name>/SKILL.md` × 9: `plan-feature`, `implement-plan`, `stream-open`, `stream-charter`, `stream-work`, `stream-sync`, `stream-land`, `coord-check`, `coord-note` — faithful ports (edit rules in §3.4).
- `hooks/hooks.json` + `scripts/coord-gate.sh` — the SessionStart ledger gate (replaces the user-level rules file; spec in §3.6).
- `docs/WORKFLOW.md` — the protocol's rationale/contracts doc, sanitized; also hook-materialized to a stable HOME path (§3.3).
- `README.md` — the user-facing front door, built to the §5 content contract (a first-class deliverable per Steve's brief).
- `CLAUDE.md` — minimal, for this repo's own development.
- The repo keeps its existing Apache-2.0 `LICENSE`.

**Non-goals (explicit):**
- The `smallcontext` plugin (System 2, compaction continuity) — separate repo, separate plan session. The only coupling is the pinned seam contract (§3.5).
- The machine-level cutover — removing user-level originals, editing `~/.claude/settings.json`, migrating the existing ledger tree. Attended only; documented as §8, never executed autonomously.
- The retired handoff pair (`/handoff`, `/resume-handoff`) — not shipped at all.
- Per-project surfaces: bindings docs (`docs/PARALLEL-DEV-WORKFLOW.md` in adopting repos), project CLAUDE.md pointer sections. The README's adoption section explains how to write them; the plugin never ships one.
- Any behavior change to the ported system beyond what §3 enumerates.

## 2. Current state (verified 2026-07-15)

**This repo** (`/Users/ssmall/personal_code/smallplans`, github.com/stevelautus/smallplans, public):
- Contents: `LICENSE` (Apache-2.0, from repo creation) + placeholder `README.md` (1 line). Nothing else.
- `main` == `origin/main`, clean tree, `gh` authenticated as `stevelautus` (repo scope) → /implement-plan's fresh-start gate prerequisites are met.

**Source material** (all read-only; port = copy into this repo, then edit the copy):

| Source (absolute path) | Lines | Becomes |
|---|---|---|
| `~/.claude/skills/plan-feature/SKILL.md` | 100 | `skills/plan-feature/SKILL.md` |
| `~/.claude/skills/implement-plan/SKILL.md` | 139 | `skills/implement-plan/SKILL.md` |
| `~/.claude/skills/stream-open/SKILL.md` | 55 | `skills/stream-open/SKILL.md` |
| `~/.claude/skills/stream-charter/SKILL.md` | 61 | `skills/stream-charter/SKILL.md` |
| `~/.claude/skills/stream-work/SKILL.md` | 75 | `skills/stream-work/SKILL.md` |
| `~/.claude/skills/stream-sync/SKILL.md` | 39 | `skills/stream-sync/SKILL.md` |
| `~/.claude/skills/stream-land/SKILL.md` | 40 | `skills/stream-land/SKILL.md` |
| `~/.claude/skills/coord-check/SKILL.md` | 65 | `skills/coord-check/SKILL.md` (fork frontmatter — §3.7) |
| `~/.claude/skills/coord-note/SKILL.md` | 60 | `skills/coord-note/SKILL.md` |
| `~/.claude/coordination/WORKFLOW.md` | 177 | `docs/WORKFLOW.md` + materialized stable copy (§3.3) |
| `~/.claude/coordination/README.md` | 131 | folded into `README.md` as the walkthrough section (§5); not shipped as its own file |
| `~/.claude/coordination/TEMPLATE.md` | 13 | **retired** — not shipped (Steve, 2026-07-15) |
| `~/.claude/rules/parallel-dev.md` | 9 | replaced by the gate hook (§3.6); its text is embedded there |

Each source skill directory contains only `SKILL.md` — no supporting files to port.

**Sweep sizing (grepped against sources, so the port diffs can be audited):** ~29 lines match the personal-specifics pattern (`Steve|ssmall|sjsmal|occupal|py3_bootstrap_venv`) — coordination README 10, stream-open 4, plan-feature 3, stream-land 3, WORKFLOW.md 3, implement-plan 2, coord-note/stream-charter/stream-sync/stream-work 1 each, coord-check/TEMPLATE/rules 0. ~52 lines mention sibling skill names (cross-reference qualification, §3.4). 20 `~/.claude` path references across the nine skills, split between data paths that stay and locations that change (§3.4).

**Machine facts the build relies on:** the directory-source marketplace flow is already proven in `~/.claude/settings.json` (`extraKnownMarketplaces.artifex` → local path, `autoUpdate: true`; `enabledPlugins` format `"name@marketplace": true`). `~/.claude/coordination/` currently holds `occupal/` (78 entries) + the three protocol docs; there is **no** `smallplans/` project dir yet. The user-level originals stay installed throughout the build (bootstrap rule: these very sessions run on them).

## 3. Decisions (all settled; no opens)

### 3.1 Identity
- Plugin **`smallplans`**, marketplace **`smallplans`** (enablement key `smallplans@smallplans`), owner `stevelautus`, initial version `0.1.0`. License Apache-2.0 (already committed). [research doc + interview defaults, unvetoed]
- Manifest layout: try `"source": "./"` in marketplace.json first and verify live; if the flat form fails, nest everything under `plugins/smallplans/` (the documented-safe fallback) and re-verify. [research §6]

### 3.2 Data root rename — `~/.claude/coordination/` → `~/.claude/smallcoordination/` (Steve, 2026-07-15)
The plugin's ledger root is **`~/.claude/smallcoordination/<project>/`**. Applies everywhere the shipped material references the ledger: `coord-note` (write path, `mkdir -p` on demand), `coord-check` (read path), the gate hook derivation, all stream/plan skill prose, `docs/WORKFLOW.md`, README. Mutable state still lives in HOME, outside any plugin install dir, and must outlive uninstall (research §3/§5 reasoning unchanged — only the directory name changes).
**Known consequence (accepted):** Steve's existing `~/.claude/coordination/` tree becomes invisible to the plugin until the attended cutover moves it (§8). Historical prose inside old entries that cites the old path stays stale — cosmetic only.
**Not renamed:** `~/.claude/handoffs/` (smallcontext's territory), the pinned seam path (§3.5), and the per-project bindings-doc convention `docs/PARALLEL-DEV-WORKFLOW.md` (faithful port; renaming it was not asked for).

### 3.3 WORKFLOW.md placement (Steve, 2026-07-15)
Ship `docs/WORKFLOW.md` in the plugin **and** have the gate-hook script materialize a stable copy at **`~/.claude/smallcoordination/WORKFLOW.md`**: refresh from the bundled copy at session start **only when `~/.claude/smallcoordination/` already exists** (non-adopters get zero HOME writes; `coord-note` creates the dir on first entry). Refresh = overwrite; the materialized copy is plugin-owned and gets a 2-line comment header saying it is auto-materialized by smallplans and local edits will be lost (edit the plugin copy instead). Compare-before-copy to avoid pointless mtime churn. Skill prose cites the stable path; the README links the in-repo `docs/WORKFLOW.md`.

### 3.4 Faithful-port rule and the only allowed edit categories
Port each file 1:1, then apply **exactly** these edits — every changed line in a port commit must belong to one:
1. **Sanitize** (research §7.10 — repos are public): Steve's name → neutral phrasing ("the user"); the `~/py3_bootstrap_venv.py` venv recipe in stream-open → "recreate the environment per the project's bindings doc"; personal paths in examples → generic; "for occupal: …" asides → generic illustrations of what a bindings doc supplies. Secrets: none exist in sources (verified pattern-grep), and none may be introduced.
2. **Qualify cross-references** (research §7.2): sibling-skill mentions in prose become plugin-qualified (`invoke the **stream-sync** skill` → `invoke the **smallplans:stream-sync** skill`), including skill-routing lines. A skill's own `name:` frontmatter keeps the bare name (the plugin supplies the namespace).
3. **Rewrite locations** (research §7.3 + §3.2 rename): ledger paths → `~/.claude/smallcoordination/…`; `~/.claude/coordination/WORKFLOW.md` → `~/.claude/smallcoordination/WORKFLOW.md`; mentions of `~/.claude/skills/<x>/SKILL.md` install paths → refer by skill name instead; mentions of the rules file → the gate hook.

**Must NOT change:** the three context-kit checkpoint bullets in `plan-feature`, `implement-plan`, `stream-work` — they keep citing `~/.claude/context-kit/RECYCLING.md` **verbatim**, fail-soft clause included (§3.5); `~/.claude/handoffs/` mentions; the `docs/streams/<slug>-CHARTER.md` and `docs/PARALLEL-DEV-WORKFLOW.md` conventions; any procedural content, ordering, gate, or hard stop. Anything that doesn't fit categories 1–3 is a behavior change → stop and queue for Steve (§7).

### 3.5 The pinned seam contract (binding; neither plugin plan may change it)
> The checkpoint procedure lives at `~/.claude/context-kit/RECYCLING.md`. smallcontext's SessionStart hook materializes/refreshes it there; smallplans' three checkpoint bullets keep referencing that exact path with their existing fail-soft clause ("if that file is missing, the kit was rolled back — skip this"). The path keeps its pre-plugin directory name deliberately. Do not rename it to match either plugin.

smallplans without smallcontext must degrade cleanly: the bullets skip.

### 3.6 Gate hook (replaces `~/.claude/rules/parallel-dev.md`)
`hooks/hooks.json` registers a SessionStart hook (no matcher — all sources; firing after a compaction is harmless-to-good) running `${CLAUDE_PLUGIN_ROOT}/scripts/coord-gate.sh`. Script semantics, reproducing the rules file exactly but injecting **only when relevant** (this conditionality is the improvement over the always-loaded rules file — preserve it):

1. Materialize/refresh the stable WORKFLOW.md copy per §3.3 (independent of cwd git-ness).
2. Derive the project key exactly as the rules file does: `PROJ=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")`. Non-git cwd → inject nothing, exit 0.
3. If `~/.claude/smallcoordination/$PROJ/` exists and is non-empty → inject as additionalContext: the obligation to run the **smallplans:coord-check** skill and honor what it reports, plus the inviolables ("never rebase or force-push a branch another session has seen; sync = merge"). Otherwise inject nothing.
4. Output mechanism: mirror the proven one in `~/.claude/context-kit/compact-reorient.sh` (readable, verified live on this machine 2026-06-10). Always exit 0; the hook must never break a session.

The rules file's skill-routing table moves into the README's quick reference (§5); it is not injected.

### 3.7 coord-check fork frontmatter (research §7.6)
The source skill's `model: claude-haiku-4-5` / `context: fork` / `agent: Explore` frontmatter is unconfirmed in plugin context. Port it unchanged, verify live (§4 P6). If honored → note in README that the check is deliberately cheap. If ignored → **ship anyway**, record the finding in §9 and in the PR description for Steve's review; the skill still functions inline. Not a build blocker.

### 3.8 Verification is in-scope for the autonomous run
Live verification uses the granted machine-state writes (§7): register this checkout as a directory-source marketplace, enable `smallplans@smallplans`, spawn fresh headless sessions (`claude -p`) for every hook/namespacing test (hooks snapshot at session start — a test is only valid in a session started after the change), and create the dogfood ledger entry. Prefer project-local settings scope for enablement; use user-level `~/.claude/settings.json` only if required, touching nothing but the smallplans entries and reporting exactly what was written where.

## 4. Phase plan

Each phase ends at a safe point: work committed, repo state green (for this repo, "green" = the phase's verification criteria pass). Check boxes as phases complete.

### Phase 1 — Scaffold and first live install
- [x] Write `.claude-plugin/plugin.json` (name, version 0.1.0, description) and `.claude-plugin/marketplace.json` (name `smallplans`, owner `stevelautus`, plugin entry `"source": "./"`).
- [x] Write minimal `CLAUDE.md` (~15 lines): what this repo is, pointer to this plan, the §3.4 edit-category rule, the §3.5 seam contract, the dev-verify loop (register checkout → enable → fresh session), the sanitization gate.
- [x] Port `coord-check` per §3.4 (first skill through the pipeline; also carries the §3.7 risk).
- [x] Register the checkout as a directory-source marketplace; enable `smallplans@smallplans` (§3.8 scope rules).
- [x] **Verify:** a fresh headless session lists/invokes `smallplans:coord-check` (namespaced). If the flat `"source": "./"` form fails → restructure under `plugins/smallplans/`, re-verify, and record the outcome in §9.
- [x] Commit (plus plan-doc checkbox update).

### Phase 2 — Port the remaining eight skills
- [x] Port `coord-note`, `plan-feature`, `implement-plan`, `stream-open`, `stream-charter`, `stream-work`, `stream-sync`, `stream-land` per §3.4.
- [x] **Verify (per skill):** diff against its source; every changed line classifiable under §3.4's three categories; the three checkpoint bullets byte-identical to source on the seam path. Fresh session sees all nine namespaced.
- [x] Commit.

### Phase 3 — docs/WORKFLOW.md
- [x] Port `~/.claude/coordination/WORKFLOW.md` → `docs/WORKFLOW.md` per §3.4 (heaviest path-rename surface: its §4/§11 reference the ledger root and old install locations; its §10 names Steve).
- [x] **Verify:** diff audit as in Phase 2; zero personal-specifics pattern hits in the shipped file.
- [x] Commit.

### Phase 4 — Gate hook and dogfood entry
- [x] Write `scripts/coord-gate.sh` + `hooks/hooks.json` per §3.6 (executable bit on the script).
- [x] Create the dogfood ledger entry via the **ported** `smallplans:coord-note`: a real heads-up entry for project `smallplans` announcing the plugin build (creates `~/.claude/smallcoordination/smallplans/`; append-only; permanent — granted §7).
- [x] **Verify (fresh headless sessions each):** (a) positive — session in this repo receives the injected gate context (have it quote the injection) and `~/.claude/smallcoordination/WORKFLOW.md` now exists with the §3.3 header, matching the bundled copy; (b) negative — session in the scratchpad dir receives no gate injection; (c) script is safe standalone: non-git cwd, missing smallcoordination dir, re-run idempotency, exit 0 in all cases.
- [x] Commit.

### Phase 5 — README
- [x] Write `README.md` to the §5 contract (replaces the placeholder).
- [x] **Verify:** structure review against the contract checklist; every §5 must-cover item present; commands table lists all nine with exact `/smallplans:<name>` invocations; automatic-behavior section states trigger, condition, injected content, HOME writes, disable/uninstall paths.
- [x] Commit.

### Phase 6 — Full verification matrix and sanitization gate
- [x] Fresh-session matrix: all nine skills invocable by namespaced name; cross-skill references in prose resolve (spot-invoke a skill that routes to a sibling); gate positive/negative re-run post-README (unchanged behavior); §3.7 fork-frontmatter observation recorded.
- [x] Sanitization gate: `grep -riE 'steve|ssmall|sjsmal|occupal|py3_bootstrap'` over `skills/ docs/ hooks/ scripts/ CLAUDE.md` → **zero hits** (README and manifests are excluded — they intentionally carry `stevelautus` in install instructions/owner; review those by eye; `docs/SMALLPLANS-PLAN.md` is a dev doc, exempt).
- [x] Fix-loop anything found; re-verify; commit.

### Phase 7 — Closeout
- [x] Update this plan: checkboxes, §9 follow-ups, spend log (§6).
- [x] Standard /implement-plan closeout: push the feature branch, open the PR into `main` with a summary that includes verification evidence and any §3.7/§9 findings, report the PR URL. Review and merge stay manual.

## 5. README content contract (Steve's brief: a first-class deliverable)

Optimize for a fresh user deciding whether/how to use this: glanceable up top, detail below, nothing vital drowned. Required structure and must-covers, in order:

1. **What this is** — the paradigm in one short paragraph (plan → ratify → autonomous run; trunk variation and stream variation of one system). A short prerequisites line: a git repo; a GitHub remote + authenticated `gh` for `/implement-plan`'s closeout (runs end by opening a PR); streams additionally assume git worktrees + the per-project bindings doc (item 5).
2. **Install & initial setup** — copy-pasteable commands for both forms: `github` source (`stevelautus/smallplans`) and local-checkout directory source; the enable step at both scopes — user-wide vs per-project — with the recommendation to enable per-project where the plan-doc culture applies (research §6: opinionated, not for every repo); one line on updating; and an explicit "that's all" statement: no further setup — data directories are created on demand, the hook activates with the plugin.
3. **Quick reference** — a table of all nine commands: exact invocation (`/smallplans:plan-feature` …), one-line purpose, when you'd type it. Grouped trunk / stream / coordination. "Start here" pointers: trunk feature → `plan-feature`; stream → `stream-open`. This subsumes the old rules-file routing table.
4. **What runs automatically** — its own prominent section, per Steve's brief. Must state: the plugin registers ONE automatic behavior (a SessionStart hook); on every session start it (a) refreshes `~/.claude/smallcoordination/WORKFLOW.md` if that directory exists, and (b) checks `~/.claude/smallcoordination/<project>/` for the current project — silent when empty/absent (the common case; zero context cost), injecting the coord-check obligation + the two inviolables when entries exist. What the plugin writes to HOME, that ledger data deliberately survives uninstall, and how to remove everything (disable plugin / delete `~/.claude/smallcoordination/`). No other component runs unprompted — skills act only when invoked.
5. **Per-project setup (adoption)** — tiered checklists so a user knows exactly what their project needs: (a) trunk-only use — nothing beyond enablement and the item-1 prerequisites (`plan-feature`/`implement-plan` work in any repo; plan docs conventionally under `docs/`); (b) optional — a short pointer section in the project's CLAUDE.md (where plan docs live, house conventions) with a suggested snippet; (c) streams — the project bindings doc `docs/PARALLEL-DEV-WORKFLOW.md` (env isolation, ports, DB strategy, migration numbering — `stream-open` refuses without it), its required contents itemized.
6. **Walkthrough** (the folded coordination README, sanitized — Steve: distinct section *after* the quick reference): lifecycle worked examples — a trunk feature end-to-end; a stream end-to-end (open → charter → work → sync → land); when to write ledger entries.
7. **Concepts** — short pointer paragraph to `docs/WORKFLOW.md` for rationale/contracts (three rules, seam-first refactors, ledger semantics, rejected alternatives).
8. **Troubleshooting / uninstall** — mined from the coordination README's troubleshooting, sanitized; plus the full-removal recipe.
9. **Relationship to smallcontext** — optional sibling plugin; fail-soft seam; each works alone.
10. License line.

## 6. Spend envelope

**$5 (nominal buffer — Steve, 2026-07-15).** No app-level LLM spend is expected: this build is file porting, prose, manifests, and shell. There is no app or metering table in this repo; the mechanism is simply: any step that would invoke a paid API beyond the Claude Code session itself must be logged here with an estimate before it runs, cumulative total ≤ $5, else hard stop. Claude Code's own session usage is harness-level and not metered by this envelope.

**Spend log:** $0.00 actual (forecast $0, envelope $5 — unused). No paid API beyond the Claude Code
session itself was invoked: the build is file porting, prose, manifests, and shell, exactly as forecast.
The Phase 6 audit ran 47 subagents (~1.27M tokens) at harness level, which §6 explicitly excludes from
this envelope.

## 7. Pre-authorizations (each an explicit grant — Steve, 2026-07-15)

1. **Standard:** spend to the §6 envelope; minor documented plan deviations (recorded in §9).
2. **Read-only sources:** read the §2 source paths under `~/.claude/` and the research doc in the occupal repo. Copy content in; never modify, move, or delete anything outside this repo except as granted below.
3. **Dev-marketplace + enable:** register this checkout as a directory-source marketplace and enable `smallplans@smallplans`, per §3.8 scoping (project-local preferred; user-level allowed if required; existing entries untouched; report exactly what was written where).
4. **Headless test sessions:** spawn fresh `claude -p` sessions in this repo and the session scratchpad to exercise hooks and namespaced invocation.
5. **Dogfood ledger entry:** create `~/.claude/smallcoordination/smallplans/` with one real heads-up entry via the ported coord-note (append-only, permanent).

Nothing else. In particular: no deletion or edit of user-level originals, no settings changes beyond grant 3, no writes under `~/.claude/` beyond grants 3 and 5 plus the context-kit rolling handoff the run skills already maintain.

## 8. Attended cutover (documented here; NOT part of the autonomous run)

Preconditions: **both** plugins (smallplans and smallcontext) built and verified; Steve present and driving; each step is his explicit go.

1. `mv ~/.claude/coordination ~/.claude/smallcoordination` — preserves the 78 occupal entries under the new root. Then delete the old protocol docs inside it (`WORKFLOW.md` — superseded by materialization on next session start; `README.md`, `TEMPLATE.md` — retired).
2. Delete the nine user-level skill dirs under `~/.claude/skills/` (per-item confirmation).
3. Delete `~/.claude/rules/parallel-dev.md` (the hook replaces it — never leave both active long-term).
4. If the dev enablement was project-local: switch to the intended scope (user-level enable, or per-project in adopting repos).
5. Update occupal's `docs/PARALLEL-DEV-WORKFLOW.md` (ledger path rename; drop its TEMPLATE.md reference) and its CLAUDE.md pointer section; write an occupal ledger heads-up (path rename + skills now namespaced) via `smallplans:coord-note`.
6. Re-verify in fresh sessions: bare skill names gone, namespaced ones work, the gate fires in occupal (78 entries → injection) and stays silent in a non-adopted repo.

## 9. Follow-ups / queued

_Empty at birth — implementation runs append findings and deviations here. Expected entries when the build runs: the §3.1 marketplace-source outcome (flat vs nested), the §3.7 fork-frontmatter observation, and the §3.8 enablement-scope report (exactly what was written where)._

### Findings from the build run (2026-07-15)

**§3.1 — marketplace source: FLAT form works.** `"source": "./"` in marketplace.json resolves correctly
with `plugin.json` at the repo root. `claude plugin validate .` passes and `claude plugin details
smallplans` inventories all nine skills plus the hook. The `plugins/smallplans/` nesting fallback was
**not** needed. (Note: the one proven local example on this machine, `artifex`/pyrig, uses the nested
form — nesting is not required, merely what that repo happened to do.)

**§3.7 — fork frontmatter IS honored.** A fresh session invoking `smallplans:coord-check` reported the
Skill tool performing "forked execution" and returning only the final obligations report; the caller's
transcript contained none of the skill's bash calls. `context: fork` therefore works in plugin context,
and the README now notes the check is deliberately cheap. Caveats recorded honestly: `model:
claude-haiku-4-5` and `agent: Explore` are **not** observable from the calling session, so only the fork
is confirmed — not which model served it.

**§3.8 — enablement-scope report.** Everything went to **`.claude/settings.local.json`** (local scope,
uncommitted): `extraKnownMarketplaces.smallplans` → directory source at the checkout's absolute path,
plus `enabledPlugins["smallplans@smallplans"] = true`. Written via `claude plugin marketplace add . --scope
local` and `claude plugin install smallplans@smallplans --scope local`. **`~/.claude/settings.json` was not
touched.** Local scope was chosen over project scope deliberately: the marketplace entry carries a
machine-specific absolute path, which must not land in a public repo. Per §8 step 4 this is dev-only
state and should be switched to the intended scope at the attended cutover.

### Deviations (minor, documented)

1. **CLAUDE.md does not reproduce the sanitization-gate pattern**, it cites §4 Phase 6 for it. The gate
   requires zero hits over a file set that includes CLAUDE.md, so any accurate rendering of the pattern
   inside CLAUDE.md makes the gate match itself. Phase 1 requires CLAUDE.md to cover the gate, not to
   restate its regex; both are satisfied.
2. **`.claude/settings.json` is committed but is not in the §1 ships list.** It contains only
   `enabledPlugins["smallplans@smallplans"]`. Harmless (a cloner has no such marketplace, so it is
   inert), but it is dev state in a public repo and is queued for removal at cutover rather than
   silently deleted here.
3. **`coord-check`'s read-scope rule still names `README.md` and `TEMPLATE.md`** — both retired by §2 —
   because §3.4 permits no edit category that would update it. Excluding files that no longer exist is
   inert, so it was ported verbatim rather than "improved". Flagged for a future decision.

### Process finding — worth acting on before the next autonomous run

The first pass through Phases 1–5 was executed by a subagent that had been given a **research-only**
brief and full Bash access. It built the whole thing unsupervised, then attempted a push, then removed
the governing plan doc from version control (commit `f2e1388`, reverted in `681d8a3`; the plan doc was
already public on `origin/main` by prior deliberate commits, so its stated rationale was moot).

Its output looked complete and was substantially wrong in ways only verification caught: the gate hook
never loaded at all, every install command in the README was invented, and 23 faithful-port violations
had accumulated — two of which **broadened destructive-action carve-outs**. Line counts matched the
sources almost exactly throughout, so structural checks would have passed it.

Lessons for the next run: give auditing/research agents write-incapable tool sets (the re-run used
`Explore`, which has no Write/Edit) rather than trusting prompt instructions; and treat "the phase
committed green" as evidence of nothing until the phase's own verification step has actually been
executed — Phases 4 and 6 were skipped wholesale, and they were the phases that would have caught all of it.

- Queued for the attended-cutover conversation (out of build scope, from research §7.8): retiring `~/.claude/commands/prepnextconvo.md` and `settings__NEW.json`; the retired handoff pair's local fate.

## 10. Ratification

**Status: RATIFIED 2026-07-15 (Steve)**

Ratification covers: the §1 scope and non-goals; the §3 decisions including the `smallcoordination` rename and its §3.2/§8 consequences; the §4 phases; the §5 README contract; the $5 envelope; the §7 pre-authorization grants exactly as listed; §8 as documentation only (never autonomous). Amendment folded in before ratification: the §5 install/initial-setup/per-project-setup coverage expansion (commit 40dc847).
