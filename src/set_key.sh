#!/bin/bash
# Takes an API key from {query} and saves it to the macOS Keychain.
set -eu

API_KEY="{query}"
SERVICE_NAME="LogSeq API Token"
ACCOUNT_NAME="logseq"

if [ -z "$API_KEY" ]; then
  printf "❌ Configuration Error\nAPI Key cannot be empty. Please provide the key after the command."
  exit 0
fi

# The -U flag updates the item if it exists, or creates it if it doesn't.
security add-generic-password -U -s "$SERVICE_NAME" -a "$ACCOUNT_NAME" -w "$API_KEY"

printf "✅ Your API key has been saved successfully to the Keychain."