#!/usr/bin/env bash
# Smoke test a production image: rake, puma, a styled page, a delayed job, and a PDF.
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

echo '== pg_repack, postgres client tools, shared libraries'
# The Dockerfile hand-lists runtime libraries; catch one the builder stage had and prod-build lacks
app env PG_MAJOR=17 sh -c '
  set -e
  for bin in /usr/lib/postgresql/$PG_MAJOR/bin/pg_repack-*; do "$bin" --version; done
  for tool in psql pg_dump; do
    version=$($tool --version)
    echo "$version"
    case "$version" in
      *" $PG_MAJOR."*) ;;
      *) echo "$tool is not version $PG_MAJOR"; exit 1 ;;
    esac
  done
  missing=$(
    { find /bundle -name "*.so" -exec ldd {} +; ldd /usr/lib/postgresql/$PG_MAJOR/bin/pg_repack-*; } 2>/dev/null \
      | awk "/^[^\t]/ { file = \$0 } /not found/ { print file, \$0 }"
  )
  [ -z "$missing" ] || { echo "unresolved shared libraries:"; echo "$missing"; exit 1; }
  
'
echo '== puma'
"${compose[@]}" up -d app
for _ in $(seq 90); do get -o /dev/null "$url/bootz" 2>/dev/null && break; sleep 2; done
get "$url/bootz"; echo

echo '== styled page'
css=$(get "$url/users/sign_in" | grep -m1 -o '/assets/[^"]*\.css' || true)
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

echo '== pdf (grover, chromium)'
app rails runner 'abort "no PDF" unless PdfGenerator.render_pdf("<p>smoke</p>").start_with?("%PDF")'

echo 'smoke test passed'
