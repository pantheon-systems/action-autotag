#!/usr/bin/env bats
#
# Tests for scripts/build-args.sh, which turns the action's 'scheme' input
# into the argument list passed to autotag.

setup() {
  BUILD_ARGS="${BATS_TEST_DIRNAME}/../scripts/build-args.sh"
}

# --- valid schemes -----------------------------------------------------------

@test "empty scheme passes only -e" {
  run "$BUILD_ARGS" ""
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "-e" ]
}

@test "omitted scheme passes only -e" {
  run "$BUILD_ARGS"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "-e" ]
}

@test "autotag scheme passes -e and --scheme autotag" {
  run "$BUILD_ARGS" "autotag"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "-e" ]
  [ "${lines[1]}" = "--scheme" ]
  [ "${lines[2]}" = "autotag" ]
}

@test "conventional scheme passes -e and --scheme conventional" {
  run "$BUILD_ARGS" "conventional"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "-e" ]
  [ "${lines[1]}" = "--scheme" ]
  [ "${lines[2]}" = "conventional" ]
}

# --e is unconditional because the action applies the 'v' prefix itself via
# TAG_PREFIX, so autotag is always asked for a bare version. Keeping it
# unconditional also means the argument array is never empty, which would
# otherwise trip 'set -u' on bash < 4.4.
@test "-e is always the first argument" {
  local scheme
  for scheme in "" "autotag" "conventional"; do
    run "$BUILD_ARGS" "$scheme"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "-e" ]
  done
}

# --scheme and its value must stay separate argv entries; collapsing them into
# a single "--scheme conventional" token makes autotag reject the flag.
@test "--scheme and its value are separate arguments, not one token" {
  run "$BUILD_ARGS" "conventional"
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = "--scheme" ]
  [ "${lines[2]}" = "conventional" ]
}

# --- invalid schemes ---------------------------------------------------------
#
# autotag itself accepts an unknown --scheme silently and falls back to its
# default bumping, so this validation is what turns a typo into a failed build
# rather than a silently wrong release version.

@test "rejects a misspelled scheme" {
  run "$BUILD_ARGS" "conventionel"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme: 'conventionel'"* ]]
}

@test "rejects a scheme differing only by case" {
  run "$BUILD_ARGS" "Conventional"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme:"* ]]
}

@test "rejects a scheme with surrounding whitespace" {
  run "$BUILD_ARGS" " conventional"
  [ "$status" -ne 0 ]
}

@test "rejects an autotag flag passed as a scheme" {
  run "$BUILD_ARGS" "--strict-match"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme:"* ]]
}

@test "error message names the accepted values" {
  run "$BUILD_ARGS" "nope"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected '', 'autotag', or 'conventional'"* ]]
}
