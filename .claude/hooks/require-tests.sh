#!/bin/bash
# Claude Code hook: changes to src/ must be followed by a full test run.
#   post-edit : PostToolUse on Write|Edit — reminds Claude when it edits a file in src/.
#   stop      : Stop — blocks finishing while src/ is newer than the last full
#               tests/RunTests.wl run, or that run (made after uncommitted src/
#               changes) failed.
# A "full" run is one whose outputs/tests.json covers the Run14n12345 and
# Hyperbolic3Manifolds suites.
root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$root" || exit 0
input=$(cat)
results=outputs/tests.json
run_cmd="/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script \"$root/tests/RunTests.wl\""

case "$1" in
post-edit)
  file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$input")
  case "$file" in
  "$root"/src/*|src/*)
    jq -n --arg msg "src/ changed ($file). Run the full test suite before finishing: $run_cmd (run it in the background; it takes a few minutes)." \
      '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}' ;;
  esac
  ;;
stop)
  # Never block twice in a row, so a failing suite cannot trap the session.
  [ "$(jq -r '.stop_hook_active // false' <<<"$input")" = true ] && exit 0
  reason=""
  if [ ! -f "$results" ]; then
    reason="outputs/tests.json is missing"
  elif [ -n "$(find src -type f -newer "$results" -print -quit)" ]; then
    reason="files in src/ changed after the last test run"
  elif ! jq -e '.Suites | has("Run14n12345") and has("Hyperbolic3Manifolds")' "$results" >/dev/null 2>&1; then
    [ -n "$(git status --porcelain -- src)" ] && reason="the last test run after the src/ changes was not a full run"
  elif ! jq -e '.Failed == 0 and .Succeeded > 0' "$results" >/dev/null 2>&1; then
    [ -n "$(git status --porcelain -- src)" ] && reason="the last full test run after the src/ changes had failures"
  fi
  if [ -n "$reason" ]; then
    jq -n --arg r "Tests required: $reason. Run $run_cmd and make sure every suite passes before finishing." \
      '{decision:"block",reason:$r}'
  fi
  ;;
esac
exit 0
