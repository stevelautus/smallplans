#!/bin/bash
# smallplans: SessionStart gate hook.
# On every session start: (1) materialize/refresh ~/.claude/smallcoordination/WORKFLOW.md
# from the bundled docs/WORKFLOW.md if the ledger dir exists; (2) if the current project's
# ledger dir has entries, inject the coord-check obligation and merge-only rule.
# Registered in hooks/hooks.json (no matcher — all sources).
# Semantics mirror ~/.claude/rules/parallel-dev.md but inject only when relevant
# (this conditionality is the improvement over the always-loaded rules file).

set -e

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

# Derive project key exactly as the rules file does
PROJ=$(cd "$CWD" 2>/dev/null && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname | xargs basename) 2>/dev/null || true

INJECT=""

# (1) Materialize/refresh the stable WORKFLOW.md copy
COORD_ROOT="$HOME/.claude/smallcoordination"
if [ -d "$COORD_ROOT" ]; then
  PLUGIN_WORKFLOW="${CLAUDE_PLUGIN_ROOT:-}/docs/WORKFLOW.md"
  STABLE_WORKFLOW="$COORD_ROOT/WORKFLOW.md"
  
  # Refresh only if the bundled copy exists and differs from the stable copy
  if [ -f "$PLUGIN_WORKFLOW" ]; then
    {
      echo "# Auto-materialized by smallplans — local edits will be lost (edit the plugin copy instead)"
      echo ""
      cat "$PLUGIN_WORKFLOW"
    } > "$STABLE_WORKFLOW.tmp" 2>/dev/null || true
    
    # Compare-before-copy to avoid pointless mtime churn
    if [ -f "$STABLE_WORKFLOW" ] && cmp -s "$STABLE_WORKFLOW" "$STABLE_WORKFLOW.tmp" 2>/dev/null; then
      rm -f "$STABLE_WORKFLOW.tmp"
    else
      mv "$STABLE_WORKFLOW.tmp" "$STABLE_WORKFLOW" 2>/dev/null || true
    fi
  fi
fi

# (2) Check if the project's ledger dir exists and is non-empty
if [ -n "$PROJ" ] && [ -d "$COORD_ROOT/$PROJ" ] && [ -n "$(ls -1 "$COORD_ROOT/$PROJ" 2>/dev/null)" ]; then
  INJECT="Session start: run the **smallplans:coord-check** skill to read standing obligations (freezes, reservations, seams, breaking changes from trunk). Inviolable everywhere: never rebase or force-push a branch another session has seen; sync = merge."
fi

# Output mechanism: mirror the pattern from ~/.claude/context-kit/compact-reorient.sh
if [ -n "$INJECT" ]; then
  jq -n --arg ctx "$INJECT" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
  jq -n '{hookSpecificOutput:{hookEventName:"SessionStart"}}'
fi

exit 0
