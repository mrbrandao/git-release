#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

ASSETS="${SCRIPT_DIR}/../assets/templates"

usage() {
  cat >&2 <<'EOF'
tpl.sh -- discover issue templates

Usage: tpl.sh [flags]
  --repo OWNER/REPO  target repo (default: cwd)
  --remote           force fetch from GitHub API
  --json             output as JSON
  -h, --help         show this help
EOF
}

# list_local -- read .github/ISSUE_TEMPLATE/ on disk.
# $1: repo root path
list_local() {
  local dir="$1/.github/ISSUE_TEMPLATE"
  [[ -d "$dir" ]] || return 1
  log "reading local templates from $dir"
  local found=0
  for f in "$dir"/*.yml; do
    [[ -f "$f" ]] || continue
    print_tpl "$f"
    found=1
  done
  return $(( !found ))
}

# list_remote -- fetch templates via gh api.
# $1: owner/repo
list_remote() {
  local repo="$1" path=".github/ISSUE_TEMPLATE"
  log "fetching templates from $repo"
  local files
  files=$(gh api "repos/$repo/contents/$path" \
    --jq '.[] | select(.name | endswith(".yml"))
    | .download_url' 2>/dev/null) \
    || return 1
  local tmp
  tmp=$(mktemp -d)
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    local fname="${url##*/}"
    curl -sL "$url" -o "$tmp/$fname"
    print_tpl "$tmp/$fname"
  done <<< "$files"
  rm -rf "$tmp"
}

# list_builtin -- list built-in fallback templates.
list_builtin() {
  log "using built-in templates"
  for f in "$ASSETS"/*.yml; do
    [[ -f "$f" ]] || continue
    print_tpl "$f"
  done
}

# print_tpl -- print one template's metadata.
# $1: path to YAML template file
print_tpl() {
  local f="$1"
  require_cmd "yq" \
    "Install: https://github.com/mikefarah/yq"
  local name desc labels prefix
  name=$(yq '.name' "$f")
  desc=$(yq '.description' "$f")
  labels=$(yq '.labels // [] | join(",")' "$f")
  prefix=$(yq '.title // ""' "$f")
  local file="${f##*/}"
  [[ "$JSON_OUT" == "true" ]] \
    && printf \
      '{"name":"%s","file":"%s","labels":"%s"' \
      "$name" "$file" "$labels" \
    && printf ',"prefix":"%s"}\n' "$prefix" \
    && return
  printf "%s (%s)\n" "$name" "$file"
  [[ -n "$labels" ]] \
    && printf "  labels: %s\n" "$labels"
  [[ -n "$prefix" ]] \
    && printf "  prefix: %s\n" "$prefix"
  printf "  %s\n\n" "$desc"
}

main() {
  setup "$@"
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
  esac

  local remote_only="false"
  has_flag "--remote" && remote_only="true"

  [[ "$remote_only" == "true" ]] \
    && { list_remote "$(detect_repo)"; return; }

  # Try local repo root first
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) \
    || root=""
  [[ -n "$root" ]] && list_local "$root" && return

  # Try remote
  list_remote "$(detect_repo)" && return

  # Fall back to built-in
  list_builtin
}

main "$@"
