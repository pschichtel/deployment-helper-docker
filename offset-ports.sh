#!/usr/bin/env bash

set -euo pipefail

input="${1?no input file}"
offset="${2?no port offset}"
output="$(mktemp)"

jq -r -n --argjson offset "$offset" --rawfile input "$input" '$input | split("\n") | map(select(length > 0)) | map(split("=") | .[0] + "=" + (.[1] | tonumber | . + $offset | tostring)) | .[]' > "$output"

