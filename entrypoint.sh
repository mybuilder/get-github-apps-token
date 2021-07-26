#!/usr/bin/env bash

highlight() { echo -e "\033[36m$*\033[0m"; }
fail() { echo -e "\033[31mERROR: $*\033[0m" >&2; exit 1; }

##
# Usage information.
##
usage() {
  cat <<-EOM
Retrieve a GitHub Apps token for the given app installation

Usage: $(highlight "./$(basename "${BASH_SOURCE[0]}") APP_ID INSTALLATION_ID PRIVATE_KEY")

Arguments:
  $(highlight APP_ID)          the ID of the GitHub Apps application
  $(highlight INSTALLATION_ID) the ID of the GitHub Apps installation
  $(highlight PRIVATE_KEY)     a private key for the given GitHub Apps application

EOM
}

##
# Verify requirements.
##
command -v jq >/dev/null || fail 'jq is missing.'
command -v curl >/dev/null || fail 'curl is missing.'
command -v openssl >/dev/null || fail 'openssl is missing.'

readonly APP_ID=$1
[[ -z "${APP_ID}" ]] && usage && fail 'Required argument APP_ID is missing.'

readonly INSTALLATION_ID=$2
[[ -z "${INSTALLATION_ID}" ]] && usage && fail 'Required argument INSTALLATION_ID is missing.'

readonly PRIVATE_KEY=$3
[[ -z "${PRIVATE_KEY}" ]] && usage && fail 'Required argument PRIVATE_KEY is missing.'

##
# Generate a JWT and use it to request a GitHub Apps token.
##
HEADER_RAW='{"alg":"RS256"}'
HEADER=$(echo -n "${HEADER_RAW}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

NOW=$(date +%s)
IAT="${NOW}"
EXP=$(( NOW + 540 ))
PAYLOAD_RAW='{"iat":'"${IAT}"',"exp":'"${EXP}"',"iss":'"${APP_ID}"'}'
PAYLOAD=$(echo -n "${PAYLOAD_RAW}" | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

HEADER_PAYLOAD="${HEADER}"."${PAYLOAD}"
SIGNATURE=$(openssl dgst -sha256 -sign <(echo -n "${PRIVATE_KEY}") <(echo -n "${HEADER_PAYLOAD}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT="${HEADER_PAYLOAD}"."${SIGNATURE}"

TOKEN_RESPONSE=$(
  curl -sX POST \
    -H "Authorization: Bearer ${JWT}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/app/installations/"${INSTALLATION_ID}"/access_tokens
)

echo "${TOKEN_RESPONSE}" | jq -r '.token'
