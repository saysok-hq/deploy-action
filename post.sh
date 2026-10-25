#!/usr/bin/env bash
# Sends one deploy to the saysOK Deploy API. Needs curl and jq.
# It never fails the job unless SAYSOK_FAIL_ON_ERROR is "true".
set -u

if [ -n "${GITHUB_ACTIONS:-}" ] && [ -n "${SAYSOK_TOKEN:-}" ]; then
  echo "::add-mask::$SAYSOK_TOKEN"
fi

fail() {
  if [ "${SAYSOK_FAIL_ON_ERROR:-false}" = "true" ]; then
    echo "::error::saysOK: deploy not recorded ($1)"
    exit 1
  fi
  echo "::warning::saysOK: deploy not recorded ($1)"
  exit 0
}

command -v jq >/dev/null 2>&1 || fail "jq is not installed"
command -v curl >/dev/null 2>&1 || fail "curl is not installed"
[ -n "${SAYSOK_URL:-}" ] || fail "no url given"
[ -n "${SAYSOK_TOKEN:-}" ] || fail "no token given"

# GitHub's job.status is success, failure or cancelled; saysOK knows success and failed.
status="${SAYSOK_STATUS:-}"
case "$status" in
  failure | cancelled) status="failed" ;;
esac

title="${SAYSOK_TITLE:-}"
[ -n "$title" ] || title="${SAYSOK_DEFAULT_TITLE:-}"

body=$(jq -n \
  --arg status "$status" \
  --arg environment "${SAYSOK_ENVIRONMENT:-}" \
  --arg title "$title" \
  --arg sha "${SAYSOK_SHA:-}" \
  --arg ref "${SAYSOK_REF:-}" \
  --arg actor "${SAYSOK_ACTOR:-}" \
  --arg url "${SAYSOK_RUN_URL:-}" \
  --arg id "${SAYSOK_ID:-}" \
  '{status: $status, environment: $environment, title: $title, sha: $sha, ref: $ref, actor: $actor, url: $url, id: $id}
   | with_entries(select(.value != ""))') || fail "could not build the request"

code=$(printf '%s' "$body" | curl -sS --max-time 15 -o /dev/null -w '%{http_code}' -X POST "$SAYSOK_URL" \
  -H "Authorization: Bearer $SAYSOK_TOKEN" -H "Content-Type: application/json" --data-binary @-) \
  || fail "the request failed${code:+, HTTP $code}"

case "$code" in
  2??)
    echo "saysOK: deploy recorded (HTTP $code)"
    exit 0
    ;;
  *) fail "HTTP $code" ;;
esac
