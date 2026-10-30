#!/usr/bin/env bash
# Smoke test a production image: rake, puma, a styled page, and a delayed job.
# Usage: docker/app/smoke/run.sh <image>
set -euo pipefail

export SMOKE_IMAGE=${1:?usage: $0 <image>}
export SMOKE_PORT=${SMOKE_PORT:-3999}
compose=(docker compose -p warehouse-smoke -f "$(dirname "$0")/compose.yml")
url="http://127.0.0.1:$SMOKE_PORT"
get() { curl -sSf -H 'X-Forwarded-Proto: https' "$@"; } # passes force_ssl
app() { "${compose[@]}" run --rm -T --no-deps app "$@"; }

cleanup() {
  local status=$?
  [ $status -eq 0 ] || "${compose[@]}" logs --no-log-prefix app | grep -v '^\s*from ' | tail -60
  "${compose[@]}" down -v
  exit $status
}
trap cleanup EXIT

echo '== rake: create, load, migrate, seed'
"${compose[@]}" up -d --wait postgres redis
app bin/db_prep

echo '== puma'
"${compose[@]}" up -d app
for _ in $(seq 90); do get -o /dev/null "$url/bootz" 2>/dev/null && break; sleep 2; done
get "$url/bootz"; echo

echo '== styled page'
css=$(get "$url/users/sign_in" | grep -o '/assets/[^"]*\.css' | head -1)
[ -n "$css" ] || { echo 'no stylesheet link'; exit 1; }
bytes=$(get -o /dev/null -w '%{content_type} %{size_download}' "$url$css")
echo "$css $bytes"
[[ $bytes == text/css* && ${bytes##* } -gt 10000 ]]

echo '== delayed job'
# Preflight calls AWS STS in production; own queue keeps seed-enqueued jobs out
app rails runner '
  AwsCredentialPreflightPlugin.force_enabled = false
  TestEmptyJob.set(queue: "smoke").perform_later
  ok, failed = Delayed::Worker.new(queues: ["smoke"]).work_off
  abort "delayed job: #{ok} ok, #{failed} failed" unless ok == 1 && failed.zero?
'

echo 'smoke test passed'
