#!/bin/bash -p

# GitHub has no API for creating fine-grained PATs, so this opens the
# token creation page with the name and permissions pre-filled.

# Usage: create-automerge-token.sh [org]
ORG="${1:-}"

read -rp "Enter the name of the PAT [AutoMerge Token]: " PAT_NAME
PAT_NAME="${PAT_NAME:-AutoMerge Token}"

read -rp "Expiration in days [90]: " EXPIRES
EXPIRES="${EXPIRES:-90}"

ENCODED_NAME=$(jq -rn --arg n "$PAT_NAME" '$n|@uri')

PERMISSIONS=(
  "statuses=read"             # Commit statuses: read-only (getCombinedStatusForRef)
  "contents=write"            # Contents: read/write (pulls.merge)
  "metadata=read"             # Metadata: read-only (required)
  "pull_requests=write"       # Pull requests: read/write (approve and merge)
  "dependabot_secrets=write"  # Dependabot secrets: read/write
  "repository_hooks=write"    # Webhooks: read/write (setup-repository.sh webhook creation)
)
QUERY=$(IFS='&'; echo "${PERMISSIONS[*]}")

URL="https://github.com/settings/personal-access-tokens/new?name=${ENCODED_NAME}&expires_in=${EXPIRES}&${QUERY}"

if [ -n "$ORG" ]; then
  URL="${URL}&target_name=$(jq -rn --arg o "$ORG" '$o|@uri')"
fi

echo "Opening token creation page."
echo "IMPORTANT: under 'Repository access', select 'All repositories' (public and private), then click 'Generate token'."
if command -v open >/dev/null; then
  open "$URL"
elif command -v xdg-open >/dev/null; then
  xdg-open "$URL"
else
  echo "$URL"
fi
