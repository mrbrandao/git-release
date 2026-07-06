#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASS=0
FAIL=0

# assert_exit -- check command exits with code.
# $1: expected exit code
# $2...: command and args
assert_exit() {
  local expected="$1"; shift
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  [[ "$actual" -eq "$expected" ]] \
    && { PASS=$((PASS+1)); return; }
  printf "FAIL: %s (expected %s, got %s)\n" \
    "$*" "$expected" "$actual" >&2
  FAIL=$((FAIL+1))
}

# -- help flag exits 0 --
for script in tpl ls new edit fields triage roadmap; do
  assert_exit 0 "${SCRIPT_DIR}/${script}.sh" --help
done

# -- missing required flags exit 1 --
assert_exit 1 "${SCRIPT_DIR}/new.sh" \
  --repo fake/repo
assert_exit 1 "${SCRIPT_DIR}/edit.sh" \
  --repo fake/repo
assert_exit 1 "${SCRIPT_DIR}/fields.sh" \
  --repo fake/repo

# -- lib.sh functions --
. "${SCRIPT_DIR}/lib.sh"

# has_flag
ARGS=("--json" "--dry-run")
has_flag "--json" \
  && PASS=$((PASS+1)) \
  || { FAIL=$((FAIL+1))
    printf "FAIL: has_flag --json\n" >&2; }
has_flag "--verbose" \
  && { FAIL=$((FAIL+1))
    printf "FAIL: has_flag --verbose false\n" >&2; } \
  || PASS=$((PASS+1))

# flag_val
ARGS=("--repo" "owner/repo" "--limit" "10")
local_repo=$(flag_val "--repo")
[[ "$local_repo" == "owner/repo" ]] \
  && PASS=$((PASS+1)) \
  || { FAIL=$((FAIL+1))
    printf "FAIL: flag_val --repo\n" >&2; }

# -- results --
printf "\n%s passed, %s failed\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
