#!/usr/bin/env bats
#
# Tests for scripts/build-args.sh, which turns the action's 'scheme' and
# 'v-prefix' inputs into the argument list passed to autotag.

setup() {
  BUILD_ARGS="${BATS_TEST_DIRNAME}/../scripts/build-args.sh"
}

# --- the -e / v-prefix coupling ---------------------------------------------
#
# -e (--empty-version-prefix) decides whether the tag autotag CREATES carries a
# 'v'. The version it prints is bare either way, so -e must track the action's
# own TAG_PREFIX exactly. Passing -e while the action prefixes 'v' makes
# autotag write tag '1.2.3' and the action push 'v1.2.3', which does not exist.

@test "v-prefix true omits -e so autotag creates the v-prefixed tag" {
  run "$BUILD_ARGS" "" "true"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "v-prefix false passes -e so autotag creates the bare tag" {
  run "$BUILD_ARGS" "" "false"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "-e" ]
}

@test "v-prefix true omits -e for every valid scheme" {
  local scheme
  for scheme in "" "autotag" "conventional"; do
    run "$BUILD_ARGS" "$scheme" "true"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" != "-e" ]
  done
}

@test "v-prefix defaults to true when omitted" {
  run "$BUILD_ARGS" ""
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "omitted scheme and v-prefix produce no arguments" {
  run "$BUILD_ARGS"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# Any non-'true' value means no 'v', matching the action's own
# [[ "$V_PREFIX" == 'true' ]] test for TAG_PREFIX.
@test "a non-true v-prefix value passes -e" {
  run "$BUILD_ARGS" "" "False"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "-e" ]
}

# --- valid schemes -----------------------------------------------------------

@test "autotag scheme with v-prefix passes only --scheme autotag" {
  run "$BUILD_ARGS" "autotag" "true"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "--scheme" ]
  [ "${lines[1]}" = "autotag" ]
}

@test "conventional scheme with v-prefix passes only --scheme conventional" {
  run "$BUILD_ARGS" "conventional" "true"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "--scheme" ]
  [ "${lines[1]}" = "conventional" ]
}

@test "conventional scheme without v-prefix passes -e and --scheme" {
  run "$BUILD_ARGS" "conventional" "false"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "-e" ]
  [ "${lines[1]}" = "--scheme" ]
  [ "${lines[2]}" = "conventional" ]
}

# --scheme and its value must stay separate argv entries; collapsing them into
# a single "--scheme conventional" token makes autotag reject the flag.
@test "--scheme and its value are separate arguments, not one token" {
  run "$BUILD_ARGS" "conventional" "true"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "--scheme" ]
  [ "${lines[1]}" = "conventional" ]
}

# An empty argument list must print nothing at all. A bare printf would emit
# one blank line, which the caller reads as an empty argv entry and autotag
# rejects as an invalid argument.
@test "empty argument list prints nothing, not a blank line" {
  run "$BUILD_ARGS" "" "true"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 0 ]
}

# --- invalid schemes ---------------------------------------------------------
#
# autotag itself accepts an unknown --scheme silently and falls back to its
# default bumping, so this validation is what turns a typo into a failed build
# rather than a silently wrong release version.

@test "rejects a misspelled scheme" {
  run "$BUILD_ARGS" "conventionel" "true"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme: 'conventionel'"* ]]
}

@test "rejects a scheme differing only by case" {
  run "$BUILD_ARGS" "Conventional" "true"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme:"* ]]
}

@test "rejects a scheme with surrounding whitespace" {
  run "$BUILD_ARGS" " conventional" "true"
  [ "$status" -ne 0 ]
}

@test "rejects an autotag flag passed as a scheme" {
  run "$BUILD_ARGS" "--strict-match" "true"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme:"* ]]
}

@test "error message names the accepted values" {
  run "$BUILD_ARGS" "nope" "true"
  [ "$status" -ne 0 ]
  [[ "$output" == *"expected '', 'autotag', or 'conventional'"* ]]
}
