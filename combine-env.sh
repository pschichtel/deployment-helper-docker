#!/usr/bin/env bash

set -euo pipefail

if [ $# -le 0 ]
then
    echo "No files to combine!" >&2
    exit 1
fi

tmp_file="$(mktemp)"
compose_args+=(--env-file "$tmp_file")

for f in "$@"
do
    if [ -r "$f" ]
    then
        cat "$f" >> "$tmp_file"
        echo "" >> "$tmp_file"
    else
        echo "Failed to read '$f'!" >&2
        exit 2
    fi
done

echo "$tmp_file"

