#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 <<'EOF'
fields.sh -- set project board fields on an issue
Usage: fields.sh --issue N --project N [flags]
  --repo OWNER/REPO   target repo (default: cwd)
  --issue NUMBER      issue number (required)
  --project NUMBER    project number (required)
  --priority VALUE    --effort VALUE
  --status VALUE      --iteration NAME
  --dry-run           --json
  -h, --help          show this help
EOF
}
# resolve_project -- get project node ID.
# $1: owner  $2: project number
resolve_project() {
  local owner="$1" num="$2" result
  result=$(gh_graphql "
    query {
      organization(login: \"$owner\") {
        projectV2(number: $num) { id }
      }
    }" 2>/dev/null \
    | jq -r '.data.organization.projectV2.id
      // empty') || true
  [[ -n "$result" ]] \
    && printf "%s" "$result" && return
  result=$(gh_graphql "
    query {
      user(login: \"$owner\") {
        projectV2(number: $num) { id }
      }
    }" | jq -r '.data.user.projectV2.id // empty')
  [[ -n "$result" ]] \
    && printf "%s" "$result" && return
  die "project #$num not found for $owner"
}
# resolve_item -- get project item ID for an issue.
resolve_item() {
  local proj="$1" repo="$2" issue="$3" issue_id
  issue_id=$(gh api "repos/$repo/issues/$issue" \
    --jq '.node_id') \
    || die "issue #$issue not found"
  gh_graphql "
    mutation {
      addProjectV2ItemById(input: {
        projectId: \"$proj\"
        contentId: \"$issue_id\"
      }) { item { id } }
    }" | jq -r '.data.addProjectV2ItemById.item.id'
}
# resolve_field -- get field ID and option ID.
resolve_field() {
  local proj="$1" name="$2" val="$3" data
  data=$(gh_graphql "
    query {
      node(id: \"$proj\") {
        ... on ProjectV2 {
          fields(first: 50) { nodes {
            ... on ProjectV2SingleSelectField {
              id name options { id name }
            }
            ... on ProjectV2IterationField {
              id name
              configuration {
                iterations { id title }
              }
            }
          }}
        }
      }
    }")
  local fid
  fid=$(printf "%s" "$data" \
    | jq -r ".data.node.fields.nodes[]
      | select(.name == \"$name\") | .id")
  [[ -z "$fid" ]] && die "field '$name' not found"
  local oid
  oid=$(printf "%s" "$data" \
    | jq -r ".data.node.fields.nodes[]
      | select(.name == \"$name\")
      | (.options // .configuration.iterations)[]
      | select((.name // .title)
        == \"$val\") | .id" | head -1)
  [[ -z "$oid" ]] \
    && die "value '$val' not found for $name"
  printf "%s %s" "$fid" "$oid"
}
# set_field -- mutate a single field value.
set_field() {
  local proj="$1" item="$2" fid="$3" oid="$4"
  gh_graphql "
    mutation {
      updateProjectV2ItemFieldValue(input: {
        projectId: \"$proj\"
        itemId: \"$item\"
        fieldId: \"$fid\"
        value: {singleSelectOptionId: \"$oid\"}
      }) { projectV2Item { id } }
    }" >/dev/null
}
# apply_field -- resolve and set one field.
apply_field() {
  local proj="$1" item="$2" name="$3" val="$4"
  [[ -z "$val" ]] && return
  log "setting $name=$val"
  local ids
  ids=$(resolve_field "$proj" "$name" "$val")
  local fid="${ids%% *}" oid="${ids##* }"
  [[ "$DRY_RUN" == "true" ]] \
    && log "dry-run: $name=$val ($fid/$oid)" \
    && return
  set_field "$proj" "$item" "$fid" "$oid"
}
main() {
  setup "$@"
  case "${1:-}" in -h|--help) usage; exit 0 ;; esac
  require_cmd "jq"
  local issue proj_num repo owner proj_id item_id
  issue=$(flag_val "--issue")
  [[ -z "$issue" ]] && die "--issue is required"
  proj_num=$(flag_val "--project")
  [[ -z "$proj_num" ]] \
    && die "--project is required"
  repo=$(detect_repo)
  owner="${repo%%/*}"
  log "resolving project #$proj_num"
  proj_id=$(resolve_project "$owner" "$proj_num")
  log "resolving issue #$issue in project"
  item_id=$(resolve_item \
    "$proj_id" "$repo" "$issue")
  apply_field "$proj_id" "$item_id" \
    "Priority" "$(flag_val '--priority')"
  apply_field "$proj_id" "$item_id" \
    "Effort" "$(flag_val '--effort')"
  apply_field "$proj_id" "$item_id" \
    "Status" "$(flag_val '--status')"
  apply_field "$proj_id" "$item_id" \
    "Iteration" "$(flag_val '--iteration')"
  [[ "$JSON_OUT" == "true" ]] \
    && printf '{"issue":%s,"fields":"set"}\n' \
      "$issue" && return
  printf "fields set for issue #%s\n" "$issue"
}
main "$@"
