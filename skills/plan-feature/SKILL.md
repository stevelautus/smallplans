---
name: plan-feature
description: >-
  Author a ratifiable plan document for a feature to be built on the current
  branch — the trunk-side sibling of /smallplans:stream-charter, with no worktree or
  stream machinery. Use when the user says "plan this feature", "write the
  plan doc for X", "let's charter this on trunk", or runs /smallplans:plan-feature,
  typically in a max-effort session. Leads a guided interview: derives what it
  can from the repo and prior plan docs, asks grouped questions with
  recommendations, resolves CONFIRMs live. Produces a plan doc whose
  ratification block, once RATIFIED, authorizes a separate /smallplans:implement-plan
  session to execute autonomously. An upfront brief may follow the command
  (e.g. `/smallplans:plan-feature add per-track digests — details: …`); it becomes the
  primary planning input and the interview shrinks to whatever it leaves open.
---

# Plan Feature

The plan document is the feature's contract: it settles *in advance* everything an autonomous
implementation run would otherwise have to ask, and it is the cold-start context for the fresh session
that executes it. This skill provides the scaffold; the content comes from a planning conversation with
the user. It replaces the old hand-written kickoff prompt — the kickoff is now just
`/smallplans:implement-plan <path>` in a fresh session.

## What the user typed after the command

Anything after `/smallplans:plan-feature` is the user's upfront brief: goals, context, constraints, decisions
already made, scope boundaries, budget thoughts. It is the highest-priority planning input and it
pre-answers interview questions:

- Decisions the brief **settles** are settled — don't re-ask them. Carry them into the step-2
  assumptions block marked "from your brief," so the user sees they landed and can correct a misread.
- Topics the brief **touches but leaves open** become targeted follow-ups, not generic questions.
- Topics the brief **doesn't reach** get the normal guided treatment.
- A spend figure or pre-authorization stated in the brief counts as user-provided; the ratification walk
  still restates every grant for final confirmation.

No brief → run the full guided interview as written.

## Procedure

1. **Orient.** Read the project's CLAUDE.md, the product docs in scope (relevant PRD or requirements sections),
   and one or two recent plan docs for house style. Derive where plan docs live from where existing ones sit
   (conventionally: `docs/<NAME>-PLAN.md`); recommend that location and confirm it in the interview.
   If `~/.claude/smallcoordination/<project>/` has entries, honor the session-start gate first — a plan that
   collides with an open stream's reserved modules or an active landing freeze must say how it avoids them.
2. **Derive before asking.** Build a draft understanding from what already exists: the brief first, then
   the motivating docs, then a recon of the affected modules — the current-state survey must be verified
   against the code with file paths, not assumed. Open by presenting numbered stated assumptions the
   user can veto, marking which came from the brief and which were derived. Never ask the user to recite
   what the artifacts — or their own brief — already say.
3. **Elicit the decisions — you lead; the user needs no prior knowledge of the format.** Ask only what
   the brief and artifacts leave open, in grouped rounds: scope and current state, then phases, then
   envelope and pre-authorizations. For each open decision: one line on what's needed and why, a
   recommended answer with tradeoffs, then the question. Number the open items (the CONFIRM idiom); use
   AskUserQuestion for discrete option sets, free conversation otherwise. Three classes of input:
   - **Derivable** → derived and stated in step 2, not asked.
   - **Judgment calls with sensible defaults** (phase ordering, doc location, verification depth) →
     propose a pick; accept fast confirmation ("defaults fine").
   - **User-only, never defaulted:** the **spend envelope** (recommend a forecast-based figure, but the
     number must come from the user) and the **pre-authorizations** (each is a conscious grant — on
     trunk there is NO standing destructive carve-out: the dev/test databases are shared, so any
     DB-rebuild or other destructive grant must be named individually and get an explicit yes).
4. **Write the plan doc** with this structure (omit nothing; mark genuinely empty sections "none"):
   - **Goal and scope** — what ships; explicit non-goals.
   - **Current state** — the verified survey, with paths.
   - **Decisions** — settled choices with their rationale; remaining numbered opens, if the user chose
     to ratify with some opens outstanding, each with its resolution owner.
   - **Phase plan with checkboxes** — the progress anchor `/smallplans:implement-plan` resumes from; each phase
     sized to end at a natural safe point and carrying its own verification criteria.
   - **Migration expectations** — how many, what they touch; trunk-numbered per project norms. If a
     stream is open, note the coordination duty (migrations landing on trunk get a ledger entry).
   - **Spend envelope** — the app-level LLM budget for implementation runs, with the metering mechanism.
   - **Pre-authorizations** — what runs may do without asking: spend to the envelope; minor documented
     plan deviations; plus only what the user explicitly granted. Nothing else.
   - **Hard-stop additions** — any plan-specific stops beyond /smallplans:implement-plan's standard set.
   - **Follow-ups / queued** — empty at birth; runs append here.
   - **Ratification block** — initially `Status: DRAFT — not ratified`, listing exactly what
     ratification covers.
5. **Commit** the plan doc on the current branch. If coordination is active and the plan is pertinent to
   other sessions, write a heads-up via the **smallplans:coord-note** skill.
6. **Ratify live.** Walk the user through the ratification block point by point. On their explicit
   ratification: update to `Status: RATIFIED <date>` (with any amendments), commit.
7. **Stop.** Do not begin implementation. Tell the user the kickoff is `/smallplans:implement-plan <path>` in a
   fresh session (typically an ultracode one), optionally with steering after the path. Do not embed any
   kickoff prompt in the plan doc itself (standing convention: planning docs never carry kickoff prompts).

## Rules

- Written for a cold reader: a fresh session with zero memory must be able to execute from the plan doc
  plus the project's CLAUDE.md alone.
- The plan doc is the single source of truth; progress (checkboxes, follow-ups, spend log) is committed
  to it as implementation advances.
- Ratification is the user's act, in conversation — never inferred, never defaulted.
- **Context checkpoint (context-kit).** Planning sessions run long: at each major milestone (assumptions
  presented, interview rounds done, doc drafted), run the measurement in
  `~/.claude/context-kit/RECYCLING.md` and follow it. If that file is missing, the kit was rolled back —
  skip this.
