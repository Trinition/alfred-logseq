#!/bin/bash
set -u

# This script handles the entire logic for posting a journal entry.
# It fetches the key, attempts to post, and handles success, auth errors, and other errors.

JOURNAL_ENTRY="{query}"

# --- 1. Fetch API Token ---
# This will result in an empty string if the key is not found.
API_TOKEN=$(security find-generic-password -s "LogSeq API Token" -a "logseq" -w 2>/dev/null || true)


# --- 2. Generate Journal Page Name ---
if [ "${journal_date_format:-}" = "ordinal" ]; then
  # Generate date with an ordinal suffix (e.g., "Sep 5th, 2025").
  DAY_OF_MONTH=$(date +%d)
  DAY_NUM=$((10#$DAY_OF_MONTH)) # Force base-10 interpretation to remove leading zero

  if [ $DAY_NUM -eq 11 ] || [ $DAY_NUM -eq 12 ] || [ $DAY_NUM -eq 13 ]; then
    SUFFIX="th"
  else
    REMAINDER=$((DAY_NUM % 10))
    case $REMAINDER in
      1) SUFFIX="st" ;;
      2) SUFFIX="nd" ;;
      3) SUFFIX="rd" ;;
      *) SUFFIX="th" ;;
    esac
  fi
  MONTH_NAME=$(date "+%b")
  YEAR=$(date "+%Y")
  TODAYS_JOURNAL_PAGE="${MONTH_NAME} ${DAY_NUM}${SUFFIX}, ${YEAR}"
else
  # Use the format string from the workflow variable. Default to YYYY-MM-DD if not set.
  FORMAT="${journal_date_format:-%Y-%m-%d}"
  TODAYS_JOURNAL_PAGE=$(date "+$FORMAT")
fi


# --- 3. Construct JSON and Make API Call ---
# Escape any '%' characters in the user input to prevent printf errors.
PERCENT_ESCAPED_JOURNAL_ENTRY=${JOURNAL_ENTRY//%/%%}
# Also escape backslashes and double quotes for valid JSON.
JSON_ESCAPED_JOURNAL_ENTRY=$(echo "$PERCENT_ESCAPED_JOURNAL_ENTRY" | sed 's/\\/\\\\/g; s/"/\\"/g')
JSON_PAYLOAD=$(printf '{"method": "logseq.Editor.appendBlockInPage", "args": ["%s", "%s"]}' "$TODAYS_JOURNAL_PAGE" "$JSON_ESCAPED_JOURNAL_ENTRY")

# We use -w to write out the HTTP status code on a new line after the body.
CURL_RESPONSE=$(curl --silent --show-error --location --request POST "$api_endpoint" \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $API_TOKEN" \
--data "$JSON_PAYLOAD" \
-w "\n%{http_code}" 2>&1)

# Extract the HTTP status code (last line) and the body (everything else).
HTTP_CODE=${CURL_RESPONSE##*$'\n'}
HTTP_BODY=${CURL_RESPONSE%$'\n'*}

# --- 4. Handle Response ---
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  printf "✅ Journal entry added."
elif [ "$HTTP_CODE" -eq 401 ]; then
  printf "❌ Authorization Error\nYour API Key is missing or invalid. Run 'ls-setkey <your_api_key>' to set it."
  exit 0
else
  printf "❌ Workflow Error\nIs LogSeq HTTP server running at $api_endpoint?\nHTTP Status: %s. Details: %s" "$HTTP_CODE" "$HTTP_BODY"
  exit 0
fi