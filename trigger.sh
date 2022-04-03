#!/usr/bin/env bash

set -euo pipefail

if [ "${DEPLOYMENT_DEBUG:-}" = "true" ]
then
    set -x
fi

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

default_branch="false"
if [ -n "${CI_COMMIT_BRANCH:-}" ]
then
    ref_type="branch"
    ref="${CI_COMMIT_BRANCH}"
    if [ "${CI_COMMIT_BRANCH}" = "${CI_DEFAULT_BRANCH}" ]
    then
        default_branch="true"
    fi
elif [ -n "${CI_COMMIT_TAG:-}" ]
then
    ref_type="tag"
    ref="${CI_COMMIT_TAG}"
    set -x
    git branch -a
    if [ -n "$(git branch -a "origin/${CI_DEFAULT_BRANCH}" --contains "refs/tags/${ref}")" ]
    then
        default_branch="true"
    fi
    set +x
elif [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-}" ] && [ "${CI_MERGE_REQUEST_SOURCE_PROJECT_ID:-}" = "$CI_PROJECT_ID" ]
then
    ref_type="branch"
    ref="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
    if [ "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" = "${CI_DEFAULT_BRANCH}" ]
    then
        default_branch="true"
    fi
else
    ref_type="commit"
    ref="$commit"
    if [ -n "$(git branch "${CI_DEFAULT_BRANCH}" --contains "${ref}")" ]
    then
        default_branch="true"
    fi
fi

project="$CI_PROJECT_NAME"
descriptors="$(discover-descriptors)"
descriptor_count="$(jq 'length' <<< "$descriptors")"

if [ "$descriptor_count" = 0 ]
then
    echo "No descriptors given!" >&2
    exit 1
fi

if [ "${DEPLOYMENT_DEBUG:-}" = "true" ]
then
    set +x
fi

curl -s -X POST \
    -F "token=${trigger_token}" \
    -F "ref=${trigger_branch}" \
    -F "variables[ARTIFACT_SOURCE_PROJECT]=${project}" \
    -F "variables[ARTIFACT_SOURCE_REF_TYPE]=${ref_type}" \
    -F "variables[ARTIFACT_SOURCE_REF]=${ref}" \
    -F "variables[ARTIFACT_SOURCE_COMMIT]=${commit}" \
    -F "variables[ARTIFACT_SOURCE_DEFAULT_BRANCH]=${default_branch}" \
    -F "variables[ARTIFACT_DESCRIPTORS]=${descriptors}" \
    "$trigger_url" \
    | jq

