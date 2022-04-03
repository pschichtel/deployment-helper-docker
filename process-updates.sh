#!/usr/bin/env bash

set -euo pipefail

update_script="${1?no update script}"

source_project="${ARTIFACT_SOURCE_PROJECT:-}"
source_ref_type="${ARTIFACT_SOURCE_REF_TYPE:-}"
source_ref="${ARTIFACT_SOURCE_REF:-}"
source_commit="${ARTIFACT_SOURCE_COMMIT?no source commit}"

if [ -z "$source_project" ]
then
    echo "No source project given!"
    exit 1
fi

if [ -z "$source_ref_type" ]
then
    echo "No source ref type given for commit ${source_commit}"
    exit 1
fi

if [ -z "$source_ref" ]
then
    echo "No source ref given for commit ${source_commit}"
    exit 1
fi

aggregated_descriptors="${ARTIFACT_DESCRIPTORS:-}"

updates_file="$(mktemp)"
if [ -n "$aggregated_descriptors" ]
then
    echo "Using pre-collected descriptors!"
    echo "$aggregated_descriptors" > "$updates_file"
else
    echo "Discovering descriptors!"
    discover-descriptors > "$updates_file"
fi

artifact_count="$(jq 'length' < "$updates_file")"
if [ "$artifact_count" = 0 ]
then
    echo "Received artifacts to update, nothing to do here!"
    exit 0
fi

echo "Project:   $source_project"
echo "Ref:       $source_ref ($source_ref_type)"
echo "Updates:   $(< "$updates_file")"

update_token="$(< "${ENV_UPDATE_TOKEN?no update token}")"
update_token_name="${ENV_UPDATE_TOKEN_NAME?no update token name}"
envs_base_dir="envs"
mkdir -p "$envs_base_dir" || echo "Envs dir already exists"

checkout_env() {
    local env="${1?no env}"
    local repo_url="https://${update_token_name}:${update_token}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}"
    local env_dir="${envs_base_dir}/${env}"
    if [ -e "$env_dir" ]
    then
        git -C "${env_dir}" pull --rebase >&2
    else
        git clone -b "$env" "$repo_url" "$env_dir" >&2
    fi
    readlink -f "$env_dir"
}

update_env() {
    local env="${1?no env}"
    local updates_file="${2?no updates file}"
    local artifacts_file="artifacts.json"

    pushd "$(checkout_env "$env")"
    if [ -r "$artifacts_file" ]
    then
        local tmp_file
        tmp_file="$(mktemp)"
        jq -n \
            --slurpfile artifacts_slurp "$artifacts_file" \
            --slurpfile updates_slurp "$updates_file" \
            '($artifacts_slurp | first) as $artifacts | $updates_slurp | first | reduce .[] as $item ($artifacts; .[$item.name] = $item.descriptor)' \
            > "$tmp_file"
        mv "$tmp_file" "$artifacts_file"

        if [ -n "$(git status --porcelain)" ]
        then
            echo "Commiting and pushing the changes ..."
            git config user.name 'Environment Update'
            git config user.email "environment-update@${CI_SERVER_HOST}"
            git add "$artifacts_file"
            git commit -m "Environment updated from ${source_project} (${source_ref_type} ${source_ref})!"
            git push
            echo 'done.'
        else
            echo "Nothing actually changed with this update."
        fi
    else
        echo "No existing ${artifacts_file} file found, nothing to update..."
    fi
    popd
    
}

apply_updates() {
    local env="${1?no env}"

    update_env "$env" "$updates_file"
}

# shellcheck disable=SC1090
source "$update_script"

