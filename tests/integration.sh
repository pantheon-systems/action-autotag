#!/bin/bash
# Integration tests: run the real, pinned autotag binary against throwaway
# git repositories to verify the flags we build are actually accepted and
# produce the version bumps we expect.
#
# No mocks and no fixture repo checked into the tree: each case builds its
# own history in a temp dir and is torn down afterwards.
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ARGS="${REPO_ROOT}/scripts/build-args.sh"

# Pull the pinned version/checksum straight from action.yml so this test can
# never drift from what the action actually downloads.
AUTOTAG_VERSION="$(sed -n 's/.*AUTOTAG_VERSION:[[:space:]]*//p' "${REPO_ROOT}/action.yml")"
AUTOTAG_SHA256="$(sed -n 's/.*AUTOTAG_SHA256:[[:space:]]*//p' "${REPO_ROOT}/action.yml")"

# The pinned binary is linux_amd64, matching the action's own download.
if [[ "$(uname -s)" != 'Linux' ]]; then
  echo "This integration test requires Linux (the pinned autotag build is linux_amd64)." >&2
  echo "Run it in CI, or via: docker run --rm -v \"\$PWD\":/w -w /w ubuntu:24.04 tests/integration.sh" >&2
  exit 1
fi

BIN_DIR="$(mktemp -d)"
trap 'rm -rf "$BIN_DIR"' EXIT

echo "Installing autotag ${AUTOTAG_VERSION}..."
curl -fsSLo "${BIN_DIR}/autotag" \
  "https://github.com/autotag-dev/autotag/releases/download/${AUTOTAG_VERSION}/autotag_linux_amd64"
echo "${AUTOTAG_SHA256}  ${BIN_DIR}/autotag" | sha256sum -c -
chmod +x "${BIN_DIR}/autotag"
AUTOTAG="${BIN_DIR}/autotag"

failures=0

# make_repo <commit-subject>...
# Creates a temp repo tagged v1.2.3, then layers on the given commits.
make_repo() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name 'Test'
  git -C "$dir" commit -q --allow-empty -m 'initial commit'
  git -C "$dir" tag v1.2.3
  local subject
  for subject in "$@"; do
    git -C "$dir" commit -q --allow-empty -m "$subject"
  done
  echo "$dir"
}

# check <description> <v-prefix> <scheme> <expected-tag> <commit-subject>...
check() {
  local desc="$1" v_prefix="$2" scheme="$3" expected="$4"
  shift 4

  local dir
  dir="$(make_repo "$@")"

  local raw
  if ! raw="$("$BUILD_ARGS" "$scheme")"; then
    echo "FAIL: ${desc}"
    echo "  build-args.sh rejected scheme '${scheme}'"
    failures=$((failures + 1))
    rm -rf "$dir"
    return
  fi

  local args=()
  while IFS= read -r arg; do
    args+=("$arg")
  done <<< "$raw"

  local prefix=""
  [[ "$v_prefix" == 'true' ]] && prefix="v"

  # Run autotag in its real tag-creating mode (no -n), matching what the
  # action does. stderr is left on the terminal rather than folded into the
  # compared value, so a warning cannot masquerade as an assertion diff.
  local actual
  if ! actual="${prefix}$(cd "$dir" && "$AUTOTAG" "${args[@]}")"; then
    echo "FAIL: ${desc} (autotag exited non-zero; see stderr above)"
    failures=$((failures + 1))
    rm -rf "$dir"
    return
  fi

  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: ${desc}"
    echo "  expected: ${expected}"
    echo "  actual:   ${actual}"
    failures=$((failures + 1))
    rm -rf "$dir"
    return
  fi

  # The tag must actually exist in the repo, since autotag ran for real.
  if ! git -C "$dir" rev-parse -q --verify "refs/tags/${actual#v}" >/dev/null &&
     ! git -C "$dir" rev-parse -q --verify "refs/tags/${actual}" >/dev/null; then
    echo "FAIL: ${desc}"
    echo "  autotag reported ${actual} but created no matching tag"
    failures=$((failures + 1))
    rm -rf "$dir"
    return
  fi

  echo "ok: ${desc} -> ${actual}"
  rm -rf "$dir"
}

# With no scheme set, autotag uses its default: patch for an ordinary commit,
# with [minor]/[major] markers read out of the subject.
check 'default scheme, patch bump'          true  ''             v1.2.4 'a normal commit'
check 'default scheme, minor marker'        true  ''             v1.3.0 'add a thing [minor]'
check 'default scheme, no v prefix'         false ''             1.2.4  'a normal commit'

# An explicit 'autotag' scheme is the same behaviour, named.
check 'explicit autotag scheme'             true  autotag        v1.2.4 'a normal commit'

# The conventional scheme reads the commit type instead.
check 'conventional, fix -> patch'          true  conventional   v1.2.4 'fix: correct a thing'
check 'conventional, feat -> minor'         true  conventional   v1.3.0 'feat: add a thing'
check 'conventional, breaking -> major'     true  conventional   v2.0.0 'feat!: change a thing'
check 'conventional, scoped breaking'       true  conventional   v2.0.0 'feat(api)!: change a thing'
check 'conventional, BREAKING CHANGE footer' true conventional   v2.0.0 'feat: change a thing

BREAKING CHANGE: the response shape changed'
# A breaking footer outranks the commit type: a fix: is still a major bump.
check 'conventional, fix with breaking footer' true conventional v2.0.0 'fix: correct a thing

BREAKING CHANGE: the response shape changed'
# Documented upstream gap: autotag v1.4.3 does NOT honour the hyphenated
# BREAKING-CHANGE: synonym that the Conventional Commits spec allows, so this
# is only a minor bump. Pinned here so a future autotag bump surfaces the change.
check 'conventional, BREAKING-CHANGE not honoured' true conventional v1.3.0 'feat: change a thing

BREAKING-CHANGE: hyphenated synonym is not recognised'
check 'conventional, no v prefix'           false conventional   1.3.0  'feat: add a thing'

# The schemes must actually differ: a bare "feat:" commit is only a patch
# bump under the default scheme, which proves the flag is taking effect.
check 'feat: is only a patch by default'    true  ''             v1.2.4 'feat: add a thing'

# An invalid scheme must fail the build rather than silently falling back.
echo "checking invalid scheme is rejected..."
if "$BUILD_ARGS" 'conventionel' >/dev/null 2>&1; then
  echo "FAIL: invalid scheme 'conventionel' was accepted"
  failures=$((failures + 1))
else
  echo "ok: invalid scheme rejected"
fi

if [[ "$failures" -gt 0 ]]; then
  echo "${failures} integration test(s) failed"
  exit 1
fi
echo "All integration tests passed"
