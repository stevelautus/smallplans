---
name: stream-charter
description: >-
  Author the stream's charter — the plan document whose ratification authorizes
  autonomous implementation. Use in a stream worktree after /smallplans:stream-open, when
  the user says "write the charter", "plan the stream", "create the plan doc
  for this feature". Produces docs/streams/<slug>-CHARTER.md committed on the
  stream branch, with the required ratification block (scope amendments, seam
  plan, reserved modules, phases, spend envelope, pre-authorizations). Leads a
  guided interview: derives what it can from the artifacts, asks grouped
  questions with recommendations for the rest — the user needs no prior
  knowledge of the charter format. An upfront brief may follow the command
  (e.g. `/smallplans:stream-charter It's time to add multi-tenant support — details: …`);
  it becomes the primary planning input and the interview shrinks to whatever
  it leaves open. Pairs with /smallplans:stream-work, which refuses to run until the
  charter is ratified.
---

# Stream Charter

The charter is the stream's contract: it settles *in advance* everything an autonomous run would otherwise have to ask, and it is the cold-start context for every future stream session (which have no path-keyed memory). This skill provides the scaffold; the content comes from a planning conversation with the user.

## What the user typed after the command

Anything after `/smallplans:stream-charter` is the user's upfront brief: goals, context, constraints, decisions already made, scope boundaries, budget thoughts. It is the highest-priority planning input and it pre-answers interview questions:

- Decisions the brief **settles** are settled — don't re-ask them. Carry them into the step-2 assumptions block marked "from your brief," so the user sees they landed and can correct a misread.
- Topics the brief **touches but leaves open** become targeted follow-ups, not generic questions.
- Topics the brief **doesn't reach** get the normal guided treatment in step 3.
- A spend figure or pre-authorization stated in the brief counts as user-provided (the never-default rule is about whose answer it is, not which channel it arrived through); the step-6 ratification walk still restates every grant for final confirmation.

No brief → run the full guided interview as written.

## Procedure

1. **Verify and orient.** Must be in a stream worktree. Read: the stream's opening ledger entry, the project bindings (`docs/PARALLEL-DEV-WORKFLOW.md`), the relevant product docs (whichever the bindings names — e.g. a PRD and the requirements sections in scope), and `~/.claude/smallcoordination/WORKFLOW.md` §3 if the work is refactor-shaped.
2. **Derive before asking.** Build a draft understanding from what already exists: the user's upfront brief first, then the feature's motivating docs, a quick recon of the affected modules, the bindings, prior plan docs. Open the conversation by presenting it as numbered stated assumptions the user can veto, marking which came from the brief and which were derived. Never ask the user to recite what the artifacts — or their own brief — already say.
3. **Elicit the decisions — you lead; the user needs no prior knowledge of the charter format.** Ask only what the brief and the artifacts leave open: skip any round the brief already settles; collapse partially covered rounds to targeted gap-filling. Walk the remaining required sections (step 4) in grouped rounds: scope and seams, then phases and reservations, then envelope and pre-authorizations. For each open decision: one line on what's needed and why it matters, a recommended answer with its tradeoffs, then the question. Number the open items (the CONFIRM idiom); use the AskUserQuestion tool for discrete option sets, free conversation otherwise. For refactor-shaped streams, the seam catalog (expand / build / contract split) is the first and heaviest round. Three classes of input:
   - **Derivable** → derived and stated in step 2, not asked.
   - **Judgment calls with sensible defaults** (phase ordering, reservation breadth, hard-stop additions) → propose a pick; accept fast confirmation ("defaults fine").
   - **User-only, never defaulted:** the **spend envelope** (recommend a forecast-based figure, but the number must come from the user) and the **pre-authorizations** (each is a conscious grant — carve-outs from standing permission rules are never assumed or bundled into "defaults fine"; name each one and get an explicit yes).
4. **Write `docs/streams/<slug>-CHARTER.md`** with this structure (omit nothing; mark genuinely empty sections "none"):
   - **Goal and scope** — what the stream delivers; explicit non-goals.
   - **Seam plan** (refactor streams) — the expand-slice catalog, each marked trunk-bound. Trunk-bound slices are landed by ATTENDED sessions, not autonomous runs; note that scope-rule amendments to tracked files (e.g. CLAUDE.md out-of-scope lists) are themselves trunk edits and land the same way.
   - **Phase plan with checkboxes** — the progress anchor `/smallplans:stream-work` resumes from. Phases sized so each ends at a natural safe point.
   - **Reserved modules** — narrow: the new modules the stream owns outright. Core shared files are protected by seams plus sync frequency, not reservations.
   - **Migration expectations** — how many, what they touch; 9xxx namespace per bindings §3.
   - **Spend envelope** — the app-level LLM budget for implementation runs (walks, rescores), with the metering note from bindings §2.
   - **Pre-authorizations** — what runs may do without asking: spend to the envelope; rebuild/drop of the stream's own `*_<slug>` DBs (the explicit carve-out from the standing destructive-action rule); minor documented plan deviations. Nothing else.
   - **Hard-stop additions** — any stream-specific stops beyond the standard set.
   - **Follow-ups / queued** — empty at birth; autonomous runs append queued trunk slices here.
   - **Ratification block** — initially `Status: DRAFT — not ratified`. Lists exactly what ratification covers, including any project scope-rule amendments required.
5. **Commit** the charter on the stream branch, then `/smallplans:coord-note` heads-up: "charter authored, pending ratification — <path>".
6. **Ratify live.** Walk the user through the ratification block point by point. On their explicit ratification: update the block to `Status: RATIFIED <date>` (with any amendments they made), commit, and note whether scope-rule amendments still need their trunk-side landing.
7. **Stop.** Do not begin implementation — tell the user the kickoff is simply `/smallplans:stream-work` in this worktree. Do not embed any kickoff prompt in the charter itself (standing convention: kickoff prompts are delivered in chat, never duplicated into planning docs).

## Rules

- Written for a cold reader: a session with zero memory must be able to execute from the charter plus the bindings alone.
- The charter is the single source of truth for the stream's plan; progress updates (checkboxes, follow-ups, spend log) are committed to it as the stream advances.
- Ratification is the user's act, in conversation — never inferred, never defaulted.
