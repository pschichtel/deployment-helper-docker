#!/usr/bin/env bash

set -euo pipefail

username_env_name="${GIT_AUTH_USERNAME_ENV:-"GIT_AUTH_USERNAME"}"
password_env_name="${GIT_AUTH_PASSWORD_ENV:-"GIT_AUTH_PASSWORD"}"
password_file_env_name="${GIT_AUTH_PASSWORD_FILE_ENV:-"GIT_AUTH_PASSWORD_FILE"}"

username="${!username_env_name:-}"
password="${!password_env_name:-}"
password_file="${!password_file_env_name:-}"

if [ -n "$password_file" ] && [ -r "$password_file" ]
then
    password="$(< "$password_file")"
fi

echo "username=$username"
echo -n "password=$password"

