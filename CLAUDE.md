# CLAUDE.md — smallplans plugin development

## What this repo is

This repo builds the **smallplans Claude Code plugin**: plan → ratify → autonomous build, in two variations (trunk-direct or worktree-coordinated). It packages nine reusable planning and execution skills.

## Governance

Development follows `/Users/ssmall/personal_code/smallplans/docs/SMALLPLANS-PLAN.md` (ratified). This is not a guide — it is the contract: all implementation decisions, scope, phases, verification criteria, and spend authorizations live there. Re-read it from disk before each session.

## Edit rules

Three categories of changes are allowed (§3.4 of the plan):

1. **Sanitize** — Remove personal identifiers (Steve's name, personal paths, occupal-specific asides).
2. **Qualify cross-references** — Sibling skill mentions become plugin-namespaced (`stream-sync` → `smallplans:stream-sync`). The skill's own frontmatter keeps the bare name.
3. **Rewrite locations** — Ledger paths → `~/.claude/smallcoordination/…`; WORKFLOW.md path updates; skill install-path references become bare names; rules-file mentions → the gate hook.

**Must NOT change:** the three checkpoint bullets in plan-feature, implement-plan, stream-work (cite `~/.claude/context-kit/RECYCLING.md` verbatim); the docs/streams/<slug>-CHARTER.md and docs/PARALLEL-DEV-WORKFLOW.md conventions; procedural content, gates, or hard stops.

Anything else is a behavior change → stop and queue for Steve.

## The pinned seam (do not rename)

The checkpoint procedure lives at `~/.claude/context-kit/RECYCLING.md`. smallplans' three checkpoint bullets keep referencing that exact path. Do not rename it to match smallcoordination. smallplans without smallcontext degrades cleanly — the bullets skip.

## Dev-verify loop

1. Register this checkout as a directory-source marketplace in `~/.claude/settings.json`.
2. Enable `smallplans@smallplans` (project-local scope preferred).
3. Spawn a fresh headless session (`claude -p`) to test hooks and namespaced invocation.
4. Commit and report results.

## Sanitization gate

Before final commit, run:
```bash
grep -riE 'steve|ssmall|sjsmal|occupal|py3_bootstrap' skills/ docs/ hooks/ scripts/ CLAUDE.md
```

Must return zero hits (README and manifests excluded — they intentionally carry `stevelautus`).
