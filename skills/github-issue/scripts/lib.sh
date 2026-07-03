#!/usr/bin/env bash
# lib.sh -- shared functions for github-issue.
# Sourced by every script. Do not execute directly.

# die -- print error to stderr and exit.
# $1: error message
die() {
  printf "error: %s\n" "$1" >&2
  exit 1
}

# log -- print diagnostic to stderr.
# $1: message
log() {
  printf ":: %s\n" "$1" >&2
}

# require_cmd -- check a command is installed.
# $1: command name
# $2: install hint (optional)
require_cmd() {
  command -v "$1" >/dev/null 2>&1 \
    && return
  die "$1 not found. ${2:-Install it to continue.}"
}

# has_flag -- check if a flag exists in args.
# $1: flag name (e.g. --json)
# Reads from ARGS array (set by setup).
has_flag() {
  local flag="$1"
  for arg in "${ARGS[@]}"; do
    [[ "$arg" == "$flag" ]] && return 0
  done
  return 1
}

# flag_val -- get value for a flag from args.
# $1: flag name (e.g. --repo)
# Returns empty string if not found.
flag_val() {
  local flag="$1" i=0
  while [[ $i -lt ${#ARGS[@]} ]]; do
    [[ "${ARGS[$i]}" == "$flag" ]] \
      && printf "%s" "${ARGS[$((i+1))]:-}" \
      && return
    i=$((i+1))
  done
}

# detect_repo -- resolve owner/repo.
# Checks --repo flag first, then git remote.
detect_repo() {
  local repo
  repo=$(flag_val "--repo")
  [[ -n "$repo" ]] && printf "%s" "$repo" && return
  local url
  url=$(git remote get-url origin 2>/dev/null) \
    || die "not in a git repo and --repo not set"
  url="${url%.git}"
  url="${url##*github.com[:/]}"
  printf "%s" "$url"
}

# confirm -- prompt before a destructive action.
# Skips prompt when DRY_RUN is set.
# $1: action description
confirm() {
  [[ "${DRY_RUN:-}" == "true" ]] && return 0
  printf "confirm: %s [y/N] " "$1" >&2
  local answer
  read -r answer
  [[ "$answer" == [yY]* ]] && return 0
  die "aborted"
}

# to_json -- compact JSON via jq.
# Reads from stdin.
to_json() {
  jq -c '.' 2>/dev/null \
    || die "jq: failed to parse input"
}

# gh_graphql -- run a GraphQL query via gh api.
# $1: query string
# Remaining args passed as -f key=val to gh.
gh_graphql() {
  local query="$1"; shift
  gh api graphql -f query="$query" "$@" \
    || die "graphql query failed"
}

# setup -- common init for all scripts.
# Call at the top of main() in every script.
# Sets ARGS, DRY_RUN, JSON_OUT globals.
setup() {
  ARGS=("$@")
  DRY_RUN="false"
  JSON_OUT="false"
  has_flag "--dry-run" && DRY_RUN="true"
  has_flag "--json" && JSON_OUT="true"
  require_cmd "gh" "Install: https://cli.github.com"
}
