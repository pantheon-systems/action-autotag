#!/bin/bash
# Build the autotag argument list from the action's inputs.
#
# Usage: build-args.sh <scheme>
#
# Prints one argument per line so the caller can read it into an array
# without relying on word splitting. Exits non-zero on an invalid scheme.
set -euo pipefail
IFS=$'\n\t'

SCHEME="${1:-}"

# The action applies the 'v' prefix itself, so autotag is always asked for a
# bare version: -e (--empty-version-prefix) tells it not to prepend its own.
args=(-e)

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

printf '%s\n' "${args[@]}"
