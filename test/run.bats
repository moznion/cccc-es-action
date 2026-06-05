#!/usr/bin/env bats
# Unit tests for scripts/run.sh — the argument-assembly logic.
#
# Strategy: replace the cccc-es binary ($BIN) with a fake that prints how many
# arguments it received and each argument on its own line. That lets us assert
# exactly which flags/options/paths run.sh forwarded, and that each token is
# passed as a separate argument (i.e. shell quoting is correct).

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  RUN="$REPO_ROOT/scripts/run.sh"

  FAKEBIN="$BATS_TEST_TMPDIR/fake-cccc-es"
  cat > "$FAKEBIN" <<'EOF'
#!/usr/bin/env bash
echo "ARGC=$#"
for a in "$@"; do echo "ARG=$a"; done
EOF
  chmod +x "$FAKEBIN"
  export BIN="$FAKEBIN"

  # run.sh uses `set -u`, so every input must be defined (empty by default).
  export INPUT_PATH="" INPUT_TABLE="" INPUT_EXT="" \
    INPUT_MAX_COGNITIVE="" INPUT_MAX_CYCLOMATIC="" INPUT_MIN="" \
    INPUT_TOP_COGNITIVE="" INPUT_TOP_CYCLOMATIC="" INPUT_NO_IGNORE="" \
    INPUT_JOBS="" INPUT_ARGS="" INPUT_OUTPUT_FILE=""
}

@test "no inputs: invokes the binary with zero arguments" {
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARGC=0"* ]]
}

@test "boolean flags are added only when set to \"true\"" {
  export INPUT_TABLE=true INPUT_NO_IGNORE=true
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARG=--table"* ]]
  [[ "$output" == *"ARG=--no-ignore"* ]]
}

@test "a boolean flag set to \"false\" is not added" {
  export INPUT_TABLE=false
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ARG=--table"* ]]
}

@test "valued options pass the name and value as separate arguments" {
  export INPUT_MAX_COGNITIVE=10 INPUT_EXT=ts,js INPUT_JOBS=4 INPUT_MIN=3
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARG=--max-cognitive"* ]]
  [[ "$output" == *"ARG=10"* ]]
  [[ "$output" == *"ARG=--ext"* ]]
  [[ "$output" == *"ARG=ts,js"* ]]
  [[ "$output" == *"ARG=-j"* ]]
  [[ "$output" == *"ARG=4"* ]]
  [[ "$output" == *"ARG=--min"* ]]
  [[ "$output" == *"ARG=3"* ]]
}

@test "an empty valued option is omitted entirely" {
  export INPUT_MAX_COGNITIVE="" INPUT_PATH="src"
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ARG=--max-cognitive"* ]]
}

@test "multiple whitespace-separated paths become separate arguments" {
  export INPUT_PATH="src lib test"
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARG=src"* ]]
  [[ "$output" == *"ARG=lib"* ]]
  [[ "$output" == *"ARG=test"* ]]
}

@test "extra raw args are split and appended" {
  export INPUT_ARGS="--foo bar" INPUT_PATH="src"
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARG=--foo"* ]]
  [[ "$output" == *"ARG=bar"* ]]
  [[ "$output" == *"ARG=src"* ]]
}

@test "output-file receives a copy of the binary output" {
  out="$BATS_TEST_TMPDIR/result.txt"
  export INPUT_OUTPUT_FILE="$out" INPUT_TABLE=true
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [ -f "$out" ]
  grep -q "ARG=--table" "$out"
}

@test "the assembled command line is echoed for visibility" {
  export INPUT_TABLE=true
  run bash "$RUN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"+ cccc-es"* ]]
}
