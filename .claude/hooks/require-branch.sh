#!/bin/bash
# Claude Code PreToolUse hook: fixes to src/ and tests/ happen on their own branch.
#   edit : Write|Edit|NotebookEdit — denies editing a file under src/ or tests/
#          while on the default branch.
#   bash : Bash — denies `git commit` on the default branch while src/ or tests/
#          has uncommitted changes (catches edits made through shell commands).
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$root" || exit 0
input=$(cat)
branch=$(git branch --show-current 2>/dev/null)
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); default=${default#origin/}
default=${default:-main}
[ "$branch" = "$default" ] || exit 0

deny() {
  jq -n --arg r "On '$default': $1 Create a branch for this fix first, e.g. git switch -c fix/<short-name> (see CLAUDE.md), then retry." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

case "$1" in
edit)
  file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
  case "$file" in
  "$root"/src/*|"$root"/tests/*|src/*|tests/*) deny "editing ${file#"$root"/} is not allowed on the default branch." ;;
  esac
  ;;
bash)
  cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
  if grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+commit' <<<"$cmd" &&
     [ -n "$(git status --porcelain -- src tests)" ]; then
    deny "committing changes to src/ or tests/ is not allowed on the default branch."
  fi
  ;;
esac
exit 0
