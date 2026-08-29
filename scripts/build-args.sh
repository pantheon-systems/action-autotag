#!/bin/bash
# Build the autotag argument list from the action's inputs.
#
# Usage: build-args.sh <scheme> <v-prefix>
#
# Prints one argument per line so the caller can read it into an array
# without relying on word splitting. Exits non-zero on an invalid scheme.
set -euo pipefail
IFS=$'\n\t'

SCHEME="${1:-}"
V_PREFIX="${2:-true}"

args=()

# -e (--empty-version-prefix) controls the prefix on the tag autotag CREATES;
# the version it prints is bare either way. So -e must track the action's own
# TAG_PREFIX: pass it only when we do NOT want a 'v', otherwise autotag writes
# tag '1.2.3' while the action goes on to push 'v1.2.3', which does not exist.
if [[ "$V_PREFIX" != 'true' ]]; then
  args+=(-e)
fi

# autotag silently accepts an unknown --scheme and falls back to its default
# bumping, so an unvalidated typo would quietly produce a wrong version.
case "$SCHEME" in
  '') ;;
  autotag|conventional) args+=(--scheme "$SCHEME") ;;
  *)
    echo "::error::Invalid value for scheme: '$SCHEME' (expected '', 'autotag', or 'conventional')" >&2
    exit 1
    ;;
esac

# The array can be empty (v-prefix with no scheme); printf with no arguments
# would still emit one blank line, which the caller would read as an empty
# argv entry and autotag would reject.
if [[ "${#args[@]}" -gt 0 ]]; then
  printf '%s\n' "${args[@]}"
fi
