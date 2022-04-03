#!/usr/bin/env bash

set -euo pipefail

trigger_url="${DEPLOYMENT_PIPELINE_TRIGGER_URL?no trigger url}"
trigger_token="${DEPLOYMENT_PIPELINE_TRIGGER_TOKEN:-"${CI_JOB_TOKEN:-}"}"
trigger_branch="${DEPLOYMENT_PIPELINE_TRIGGER_BRANCH:-main}"

if [ -r "$trigger_token" ]
then
    trigger_token="$(< "$trigger_token")"
fi

if [ -z "$trigger_token" ]
then
    echo "No trigger token available!" >&2
    exit 1
fi

commit="${CI_COMMIT_SHA?no commit}"

if [ -n "${CI_COMMIT_BRANCH:-}" ]
then
    ref_type="branch"
    ref="${CI_COMMIT_BRANCH}"
elif [ -n "${CI_COMMIT_TAG:-}" ]
then
    ref_type="tag"
    ref="${CI_COMMIT_TAG}"
elif [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-}" ] && [ "${CI_MERGE_REQUEST_SOURCE_PROJECT_ID:-}" = "$CI_PROJECT_ID" ]
then
    ref_type="branch"
    ref="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
else
    ref_type="commit"
    ref="$commit"
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
    -F "variables[ARTIFACT_SOURCE_PROJECT]=${project}" \
    -F "variables[ARTIFACT_SOURCE_REF_TYPE]=${ref_type}" \
    -F "variables[ARTIFACT_SOURCE_REF]=${ref}" \
    -F "variables[ARTIFACT_SOURCE_COMMIT]=${commit}" \
    -F "variables[ARTIFACT_DESCRIPTORS]=${descriptors}" \
    "$trigger_url" \
    | jq

