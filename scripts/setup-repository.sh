#!/bin/bash -p

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <repository_relative_path>"
  echo "Example: $0 gh_user/my_repo"
  exit 1
fi

if ! python3 -c "import nacl" 2>/dev/null; then
  echo "Error: PyNaCl is required but not installed."
  echo "Install it with: pip3 install pynacl"
  exit 1
fi

REPO="${1%/}"
read -rsp "Enter your GitHub token: " GH_TOKEN
echo
read -rsp "Enter your webhook secret (leave blank to skip webhook creation): " SECRET
echo

if [ -n "$SECRET" ]; then
  curl -sS -X POST "https://api.github.com/repos/${REPO}/hooks" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
    {
      "name": "web",
      "active": true,
      "events": [
        "push",
        "pull_request",
        "check_run",
        "issue_comment",
        "repository"
      ],
      "config": {
        "url": "https://jenkins.flowlogix.com/github-webhook/",
        "content_type": "json",
        "secret": "$SECRET"
      }
    }
EOF
fi

# Create a Dependabot secret for automerge token
## Fetch the public key for the repository
public_key_response=$(curl -sS -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/dependabot/secrets/public-key")

KEY_ID=$(echo "$public_key_response" | jq -r .key_id)
PUBLIC_KEY=$(echo "$public_key_response" | jq -r .key)

# Encrypt the secret using the public key (requires python and PyNaCl)
ENCRYPTED_VALUE=$(python3 -c "
import sys, base64
from nacl import encoding, public
key = public.PublicKey(base64.b64decode('$PUBLIC_KEY'), encoding.RawEncoder())
sealed_box = public.SealedBox(key)
encrypted = sealed_box.encrypt(b'$GH_TOKEN')
print(base64.b64encode(encrypted).decode())
")

curl -sS -X PUT "https://api.github.com/repos/${REPO}/dependabot/secrets/GH_AUTOMERGE_TOKEN" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  -d "{\"encrypted_value\":\"$ENCRYPTED_VALUE\",\"key_id\":\"$KEY_ID\"}"
