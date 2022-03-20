#!/usr/bin/env bash

set -euo pipefail

input="${1?no input file}"
output="$(mktemp)"
jq -r 'to_entries | map(.key + "=" + .value) | .[]' < "$input" > "$output"
echo "$output"

