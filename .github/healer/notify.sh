#!/usr/bin/env bash
# POST a pipeline event to the bot (/api/pipeline-events) from a GitHub Actions job: the GitHub version of
# deploy/pipelines/templates/notify-bot.yml. Needs `az` signed in (azure/login with OIDC as the pipeline identity, which
# holds the Healer.Events.Write app role). Never fails the workflow.
#
#   notify.sh <event> <stage> [message]
#   env: HEALER_BOT_URL, HEALER_BOT_RESOURCE, HEALER_APP_ID, HEALER_COMMIT_SHA (default GITHUB_SHA)
set -uo pipefail
EVENT="$1"; STAGE="$2"; MESSAGE="${3:-}"
SHA="${HEALER_COMMIT_SHA:-$GITHUB_SHA}"
RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
token="$(az account get-access-token --resource "$HEALER_BOT_RESOURCE" --query accessToken -o tsv 2>/dev/null)" || {
  echo "::warning::Could not get a token for the bot; event ${EVENT} not sent"; exit 0; }
# GitHub run ids do not fit the bot's run id; the run is identified by its URL.
body="$(jq -n --arg e "$EVENT" --arg c "$SHA" --arg u "$RUN_URL" --arg s "$STAGE" --arg m "$MESSAGE" --arg a "$HEALER_APP_ID" \
  '{event: $e, commitSha: $c, runUrl: $u, stage: $s, appId: $a} + (if $m == "" then {} else {message: $m} end)')"
if curl -fsS --retry 3 --retry-delay 5 --max-time 30 -X POST -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" \
     -d "$body" "${HEALER_BOT_URL%/}/api/pipeline-events" >/dev/null; then
  echo "Bot notified: ${EVENT} (${STAGE})"
else
  echo "::warning::Bot notification ${EVENT} failed"
fi
exit 0
