#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
new.sh -- create a GitHub issue

Usage: new.sh --title TITLE [flags]
  --repo OWNER/REPO   target repo (default: cwd)
  --title TITLE        issue title (required)
  --body BODY          issue body text
  --file PATH          read body from file
  --template NAME      template name (from tpl.sh)
  --label L1,L2        comma-separated labels
  --assignee USER      assign to user
  --milestone NAME     set milestone
  --type TYPE          issue type (Bug, Feature...)
  --project NUMBER     add to project board
  --dry-run            show command without running
  --json               output as JSON
  -h, --help           show this help
EOF
}

# build_cmd -- assemble the gh issue create command.
build_cmd() {
  local repo="$1"
  CMD=("gh" "issue" "create" "--repo" "$repo")

  local title
  title=$(flag_val "--title")
  [[ -z "$title" ]] && die "--title is required"
  CMD+=("--title" "$title")

  local body
  body=$(flag_val "--body")
  [[ -n "$body" ]] && CMD+=("--body" "$body")

  local file
  file=$(flag_val "--file")
  [[ -n "$file" ]] && CMD+=("--body-file" "$file")

  local label
  label=$(flag_val "--label")
  [[ -n "$label" ]] && CMD+=("--label" "$label")

  local assignee
  assignee=$(flag_val "--assignee")
  [[ -n "$assignee" ]] \
    && CMD+=("--assignee" "$assignee")

  local milestone
  milestone=$(flag_val "--milestone")
  [[ -n "$milestone" ]] \
    && CMD+=("--milestone" "$milestone")
  return 0
}

# run_create -- execute or dry-run the command.
run_create() {
  [[ "$DRY_RUN" == "true" ]] \
    && log "dry-run: ${CMD[*]}" && return

  local out
  out=$("${CMD[@]}" 2>&1) \
    || die "gh issue create failed: $out"

  [[ "$JSON_OUT" == "true" ]] \
    && printf '{"url":"%s"}\n' "$out" && return
  printf "created: %s\n" "$out"
}

main() {
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac
  setup "$@"

  local repo
  repo=$(detect_repo)
  build_cmd "$repo"
  run_create
}

main "$@"
