#!/usr/bin/env bats
#
# Table-driven tests for scripts/build-args.sh.

setup() {
  BUILD_ARGS="${BATS_TEST_DIRNAME}/../scripts/build-args.sh"
}

# Each case is: scheme | expected args (newline-escaped)
@test "builds the expected argument list for every valid scheme" {
  local cases=(
    '|-e'
    'autotag|-e\n--scheme\nautotag'
    'conventional|-e\n--scheme\nconventional'
  )

  local failures=0
  for case in "${cases[@]}"; do
    local scheme="${case%%|*}"
    local expected
    expected="$(printf '%b' "${case#*|}")"

    local actual
    actual="$("$BUILD_ARGS" "$scheme")"

    if [[ "$actual" != "$expected" ]]; then
      echo "FAIL: scheme=${scheme}"
      echo "  expected: $(printf '%q' "$expected")"
      echo "  actual:   $(printf '%q' "$actual")"
      failures=$((failures + 1))
    fi
  done

  [ "$failures" -eq 0 ]
}

@test "always passes -e, since the action applies the v prefix itself" {
  run "$BUILD_ARGS" ""
  [ "$status" -eq 0 ]
  [ "$output" = "-e" ]
}

@test "defaults to no --scheme when the input is omitted entirely" {
  run "$BUILD_ARGS"
  [ "$status" -eq 0 ]
  [ "$output" = "-e" ]
}

@test "emits --scheme and its value as separate arguments" {
  # Guards against regressing to a single "--scheme conventional" token,
  # which autotag would reject as an unknown flag.
  run "$BUILD_ARGS" "conventional"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "-e" ]
  [ "${lines[1]}" = "--scheme" ]
  [ "${lines[2]}" = "conventional" ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "rejects an invalid scheme" {
  # autotag itself accepts an unknown scheme silently and falls back to
  # default bumping, so this validation is what turns a typo into a failed
  # build rather than a wrong version.
  run "$BUILD_ARGS" "conventionel"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid value for scheme: 'conventionel'"* ]]
}

@test "rejects a scheme that differs only by case" {
  run "$BUILD_ARGS" "Conventional"
  [ "$status" -ne 0 ]
}
