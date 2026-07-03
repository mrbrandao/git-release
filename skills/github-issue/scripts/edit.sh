#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
edit.sh -- update GitHub issue metadata

Usage: edit.sh --issue NUMBER [flags]
  --repo OWNER/REPO    target repo (default: cwd)
  --issue NUMBER       issue number (required)
  --title TITLE        new title
  --body BODY          new body text
  --file PATH          read body from file
  --add-label L1,L2    add labels
  --rm-label L1,L2     remove labels
  --assignee USER      set assignee
  --milestone NAME     set milestone
  --state open|closed  change state
  --type TYPE          set issue type
  --dry-run            show without running
  --json               output as JSON
  -h, --help           show this help
EOF
}

# build_cmd -- assemble gh issue edit command.
build_cmd() {
  local repo="$1"
  local issue
  issue=$(flag_val "--issue")
  [[ -z "$issue" ]] && die "--issue is required"
  CMD=("gh" "issue" "edit" "$issue" \
    "--repo" "$repo")

  local title
  title=$(flag_val "--title")
  [[ -n "$title" ]] && CMD+=("--title" "$title")

  local body
  body=$(flag_val "--body")
  [[ -n "$body" ]] && CMD+=("--body" "$body")

  local file
  file=$(flag_val "--file")
  [[ -n "$file" ]] \
    && CMD+=("--body-file" "$file")

  local add_label
  add_label=$(flag_val "--add-label")
  [[ -n "$add_label" ]] \
    && CMD+=("--add-label" "$add_label")

  local rm_label
  rm_label=$(flag_val "--rm-label")
  [[ -n "$rm_label" ]] \
    && CMD+=("--remove-label" "$rm_label")

  local assignee
  assignee=$(flag_val "--assignee")
  [[ -n "$assignee" ]] \
    && CMD+=("--add-assignee" "$assignee")

  local milestone
  milestone=$(flag_val "--milestone")
  [[ -n "$milestone" ]] \
    && CMD+=("--milestone" "$milestone")

  local issue_type
  issue_type=$(flag_val "--type")
  [[ -n "$issue_type" ]] \
    && CMD+=("--type" "$issue_type")
  return 0
}

# close_or_reopen -- handle state changes separately.
# gh issue edit does not support --state.
close_or_reopen() {
  local repo="$1"
  local issue
  issue=$(flag_val "--issue")
  local state
  state=$(flag_val "--state")
  [[ -z "$state" ]] && return

  local action="reopen"
  [[ "$state" == "closed" ]] && action="close"

  [[ "$DRY_RUN" == "true" ]] \
    && log "dry-run: gh issue $action $issue" \
    && return
  gh issue "$action" "$issue" \
    --repo "$repo" >/dev/null 2>&1 \
    || die "failed to $action issue #$issue"
  log "issue #$issue state changed to $state"
}

# run_edit -- execute or dry-run the command.
run_edit() {
  [[ "$DRY_RUN" == "true" ]] \
    && log "dry-run: ${CMD[*]}" && return

  "${CMD[@]}" >/dev/null 2>&1 \
    || die "gh issue edit failed"

  local issue
  issue=$(flag_val "--issue")

  [[ "$JSON_OUT" == "true" ]] \
    && printf '{"issue":%s,"status":"updated"}\n' \
      "$issue" \
    && return
  printf "updated: issue #%s\n" "$issue"
}

main() {
  setup "$@"
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac

  local repo
  repo=$(detect_repo)
  build_cmd "$repo"

  # Only run edit if flags beyond issue/repo exist
  [[ ${#CMD[@]} -gt 6 ]] && run_edit
  close_or_reopen "$repo"
}

main "$@"
