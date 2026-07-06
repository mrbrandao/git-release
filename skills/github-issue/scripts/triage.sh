#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
triage.sh -- bulk dump issues for triage

Usage: triage.sh [flags]
  --repo OWNER/REPO    target repo (default: cwd)
  --state STATE        open|closed|all (default: open)
  --no-priority        only issues missing priority
  --no-assignee        only unassigned issues
  --label LABEL        filter by label
  --limit N            max results (default: 50)
  --json               output as JSON
  -h, --help           show this help
EOF
}

# fetch_issues -- get issues with metadata.
# $1: repo
fetch_issues() {
  local repo="$1"
  local state limit label
  state=$(flag_val "--state")
  limit=$(flag_val "--limit")
  label=$(flag_val "--label")

  local fields
  fields="number,title,labels,assignees"
  fields="$fields,createdAt,state"
  local cmd=(
    "gh" "issue" "list"
    "--repo" "$repo"
    "--state" "${state:-open}"
    "--limit" "${limit:-50}"
    "--json" "$fields"
  )
  [[ -n "$label" ]] && cmd+=("--label" "$label")
  "${cmd[@]}" 2>/dev/null \
    || die "failed to fetch issues"
}

# build_jq_filter -- apply --no-priority/--no-assignee.
# Outputs a jq filter string.
build_jq_filter() {
  local jq_filter="."
  has_flag "--no-assignee" \
    && jq_filter="$jq_filter
      | map(select(.assignees | length == 0))"
  has_flag "--no-priority" \
    && jq_filter="$jq_filter
      | map(select(
          [.labels[].name]
          | map(test(\"priority\"; \"i\"))
          | any | not))"
  printf "%s" "$jq_filter"
}

# format_text -- render issues as compact text.
# Reads JSON array from stdin.
format_text() {
  jq -r '
    .[] | "#\(.number)  \(.title)
     labels: \(
       [.labels[].name] | join(", ")
       | if . == "" then "none" else . end)
     assignees: \(
       [.assignees[].login] | join(", ")
       | if . == "" then "none" else . end)
     created: \(.createdAt[:10])
"' 2>/dev/null
}

main() {
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac
  setup "$@"

  local repo
  repo=$(detect_repo)
  local data
  data=$(fetch_issues "$repo")

  local filter
  filter=$(build_jq_filter)
  data=$(printf "%s" "$data" | jq "$filter")

  local count
  count=$(printf "%s" "$data" | jq 'length')
  log "$count issues for triage"

  [[ "$JSON_OUT" == "true" ]] \
    && printf "%s\n" "$data" | to_json && return
  printf "%s\n" "$data" | format_text
  printf "%s issues total\n" "$count"
}

main "$@"
