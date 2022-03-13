#!/usr/bin/env bash

set -euo pipefail

trigger_url="${DEPLOYMENT_PIPELINE_TRIGGER_URL?no trigger url}"
trigger_token="${DEPLOYMENT_PIPELINE_TRIGGER_TOKEN?no trigger token}"
trigger_branch="${DEPLOYMENT_PIPELINE_TRIGGER_BRANCH:-main}"

if [ -r "$trigger_token" ]
then
    trigger_token="$(< "$trigger_token")"
fi

branch="${CI_COMMIT_BRANCH:-}"
tag="${CI_COMMIT_TAG:-}"

if [ -n "$branch" ]
then
    ref="branch/$branch"
elif [ -n "$tag" ]
then
    ref="tag/$tag"
else
    ref="commit/$CI_COMMIT_SHA"
fi

project="$CI_PROJECT_NAME"
descriptors="$(discover-descriptors)"
descriptor_count="$(jq 'length' <<< "$descriptors")"

if [ "$descriptor_count" = 0 ]
then
    echo "No descriptors given!" >&2
    exit 1
fi

curl -s -X POST \
    -F "token=${trigger_token}" \
    -F "ref=${trigger_branch}" \
    -F "variables[ARTIFACT_SOURCE]=${project}" \
    -F "variables[ARTIFACT_SOURCE_REF]=${ref}" \
    -F "variables[ARTIFACT_DESCRIPTORS]=${descriptors}" \
    "$trigger_url" \
    | jq

