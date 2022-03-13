#!/usr/bin/env bash

jq -n 'env | to_entries | map(select(.key | startswith("ARTIFACT_DESCRIPTOR_"))) | map({name: .key[20:], descriptor: .value})'

