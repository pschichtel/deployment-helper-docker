#!/usr/bin/env bash

set -euo pipefail

variable="${1?no variable name}"
value="${2?no value}"
input="${3?no input file}"

output="$(mktemp)"
export "$variable=$value"
if envsubst '${'"$variable"'}' < "$input" > "$output"
then
    mv "$output" "$input"
fi