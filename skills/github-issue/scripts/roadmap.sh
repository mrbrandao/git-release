#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
roadmap.sh -- aggregate issues for planning

Usage: roadmap.sh [flags]
  --repo OWNER/REPO      target repo (default: cwd)
  --project NUMBER       project number
  --group-by FIELD       milestone|priority|iteration
                         (default: milestone)
  --state STATE          open|closed|all (default: open)
  --json                 output as JSON
  -h, --help             show this help
EOF
}

# fetch_issues -- get issues with grouping metadata.
# $1: repo
fetch_issues() {
  local repo="$1"
  local state
  state=$(flag_val "--state")
  gh issue list \
    --repo "$repo" \
    --state "${state:-open}" \
    --limit 200 \
    --json "number,title,labels,assignees,milestone" \
    2>/dev/null \
    || die "failed to fetch issues"
}

# group_by_milestone -- group issues by milestone.
# Reads JSON from stdin.
group_by_milestone() {
  jq -r '
    group_by(.milestone.title // "No milestone")
    | map({
        group: (.[0].milestone.title
          // "No milestone"),
        count: length,
        issues: [.[] | {
          number, title,
          assignee: (
            [.assignees[].login] | join(",")
          )
        }]
      })
    | sort_by(
        if .group == "No milestone" then "zzz"
        else .group end
      )' 2>/dev/null
}

# group_by_label -- group by a label prefix.
# $1: prefix (e.g. "priority")
# Reads JSON from stdin.
group_by_label() {
  local prefix="$1"
  jq -r --arg p "$prefix" '
    map(. + {
      group_key: (
        [.labels[].name
          | select(startswith($p))]
        | first // "No \($p)")
    })
    | group_by(.group_key)
    | map({
        group: .[0].group_key,
        count: length,
        issues: [.[] | {
          number, title,
          assignee: (
            [.assignees[].login] | join(",")
          )
        }]
      })' 2>/dev/null
}

# format_text -- render grouped data as text.
# Reads grouped JSON from stdin.
format_text() {
  jq -r '.[] |
    "## \(.group) (\(.count) issues)\n" +
    (.issues[] |
      "  #\(.number)  \(.title)" +
      if .assignee != ""
      then "  [\(.assignee)]"
      else "" end
    ) + "\n"' 2>/dev/null
}

main() {
  setup "$@"
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac

  local repo
  repo=$(detect_repo)
  local data
  data=$(fetch_issues "$repo")

  local group_by
  group_by=$(flag_val "--group-by")
  group_by="${group_by:-milestone}"

  local grouped
  case "$group_by" in
    milestone)
      grouped=$(printf "%s" "$data" \
        | group_by_milestone)
      ;;
    priority)
      grouped=$(printf "%s" "$data" \
        | group_by_label "priority")
      ;;
    *)
      die "unsupported --group-by: $group_by"
      ;;
  esac

  [[ "$JSON_OUT" == "true" ]] \
    && printf "%s\n" "$grouped" | to_json && return
  printf "%s\n" "$grouped" | format_text
}

main "$@"
