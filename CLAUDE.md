# CLAUDE.md — smallplans plugin development

## What this repo is

This repo builds the **smallplans Claude Code plugin**: plan → ratify → autonomous build, in two variations (trunk-direct or worktree-coordinated). It packages nine reusable planning and execution skills. The repo doubles as its own marketplace.

## Governance

Development follows `docs/SMALLPLANS-PLAN.md` (ratified). This is not a guide — it is the contract: all implementation decisions, scope, phases, verification criteria, and spend authorizations live there. Re-read it from disk before each session.

## Edit rules

The skills are **ports, not originals** — each `skills/<name>/SKILL.md` was copied 1:1 from a user-level skill. Three categories of change are allowed against a source (§3.4 of the plan):

1. **Sanitize** — no real names, personal paths, or project-specific asides; these repos are public.
2. **Qualify cross-references** — sibling skill mentions become plugin-namespaced (`stream-sync` → `smallplans:stream-sync`). A skill's own frontmatter keeps the bare name.
3. **Rewrite locations** — ledger paths → `~/.claude/smallcoordination/…`; WORKFLOW.md path updates; skill install-path references become bare names; rules-file mentions → the gate hook.

**Must NOT change:** the three checkpoint bullets in plan-feature, implement-plan, stream-work (they cite `~/.claude/context-kit/RECYCLING.md` verbatim); `~/.claude/handoffs/` mentions; the `docs/streams/<slug>-CHARTER.md` and `docs/PARALLEL-DEV-WORKFLOW.md` conventions; procedural content, ordering, gates, or hard stops.

Anything else is a behavior change → stop and queue it for the user.

## The pinned seam (do not rename)

The checkpoint procedure lives at `~/.claude/context-kit/RECYCLING.md`, materialized there by the sibling plugin **smallcontext**. This plugin's three checkpoint bullets keep referencing that exact path, fail-soft clause included. The path keeps its pre-plugin name deliberately — do not rename it to match either plugin. smallplans without smallcontext degrades cleanly: the bullets skip.

## Dev-verify loop

Plugin registration and hooks **snapshot at session start**, so a change is only proven in a session started after it — editing and re-testing in the same session proves nothing.

1. Register this checkout as a directory-source marketplace (`claude plugin marketplace add . --scope local`).
2. Enable `smallplans@smallplans` (local scope keeps the machine-specific path out of the public repo).
3. Exercise it in a **fresh** headless session (`claude -p`) for hook and namespaced-invocation tests.

## Sanitization gate

Before any commit touching shipped material, run the personal-specifics gate defined in the plan (§4, Phase 6) over `skills/ docs/ hooks/ scripts/ CLAUDE.md`. It must return **zero hits**.

The exact pattern lives in the plan rather than here on purpose: writing it out in a file the gate scans would make the gate match itself. `README.md` and the manifests are exempt — they intentionally carry the owner handle in install instructions and manifest fields; `docs/SMALLPLANS-PLAN.md` is a dev doc, also exempt.
