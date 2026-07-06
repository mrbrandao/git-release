#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
ls.sh -- list/search GitHub issues

Usage: ls.sh [flags]
  --repo OWNER/REPO    target repo (default: cwd)
  --state STATE        open|closed|all (default: open)
  --label L1,L2        filter by labels
  --assignee USER      filter by assignee
  --milestone NAME     filter by milestone
  --search QUERY       free text search
  --limit N            max results (default: 30)
  --json               output as JSON
  -h, --help           show this help
EOF
}

# build_cmd -- assemble gh issue list command.
build_cmd() {
  local repo="$1"
  CMD=("gh" "issue" "list" "--repo" "$repo")

  local state
  state=$(flag_val "--state")
  CMD+=("--state" "${state:-open}")

  local limit
  limit=$(flag_val "--limit")
  CMD+=("--limit" "${limit:-30}")

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

  local search
  search=$(flag_val "--search")
  [[ -n "$search" ]] \
    && CMD+=("--search" "$search")

  [[ "$JSON_OUT" == "true" ]] \
    && CMD+=("--json" \
      "number,title,labels,assignees,state")
}

main() {
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac
  setup "$@"

  local repo
  repo=$(detect_repo)
  build_cmd "$repo"

  local out
  out=$("${CMD[@]}" 2>&1) \
    || die "gh issue list failed: $out"

  [[ "$JSON_OUT" == "true" ]] \
    && printf "%s\n" "$out" | to_json && return
  printf "%s\n" "$out"
}

main "$@"
