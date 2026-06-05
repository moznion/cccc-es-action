#!/usr/bin/env bash
# Run cccc-es as a complexity gate over the requested paths.
#
# Inputs (environment variables, set by action.yml):
#   BIN                  Absolute path to the installed cccc-es binary.
#   INPUT_PATH           Whitespace-separated files/directories to analyze.
#   INPUT_TABLE / INPUT_NO_IGNORE                  Boolean flags ("true"/...).
#   INPUT_EXT / INPUT_MAX_COGNITIVE / INPUT_MAX_CYCLOMATIC /
#   INPUT_MIN / INPUT_TOP_COGNITIVE / INPUT_TOP_CYCLOMATIC / INPUT_JOBS
#                                                  Optional valued options.
#   INPUT_ARGS           Extra raw arguments appended verbatim.
#   INPUT_OUTPUT_FILE    If set, also write output to this file.
set -euo pipefail

args=()
add_opt()  { if [ -n "$2" ];        then args+=("$1" "$2"); fi; }
add_flag() { if [ "$2" = "true" ];  then args+=("$1");      fi; }

add_flag --table          "$INPUT_TABLE"
add_flag --no-ignore      "$INPUT_NO_IGNORE"
add_opt  --ext            "$INPUT_EXT"
add_opt  --max-cognitive  "$INPUT_MAX_COGNITIVE"
add_opt  --max-cyclomatic "$INPUT_MAX_CYCLOMATIC"
add_opt  --min            "$INPUT_MIN"
add_opt  --top-cognitive  "$INPUT_TOP_COGNITIVE"
add_opt  --top-cyclomatic "$INPUT_TOP_CYCLOMATIC"
add_opt  -j               "$INPUT_JOBS"

# Extra raw args and target paths (whitespace-separated).
read -r -a extra <<< "$INPUT_ARGS"
read -r -a paths <<< "$INPUT_PATH"

set -- "${args[@]+"${args[@]}"}" "${extra[@]+"${extra[@]}"}" "${paths[@]+"${paths[@]}"}"
echo "+ cccc-es $*"
if [ -n "$INPUT_OUTPUT_FILE" ]; then
  "$BIN" "$@" | tee "$INPUT_OUTPUT_FILE"
else
  "$BIN" "$@"
fi
