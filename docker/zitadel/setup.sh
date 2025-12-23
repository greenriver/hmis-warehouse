#!/bin/sh
# Zitadel Setup Script
# Configures Zitadel with the necessary applications for Dex integration
#
# Can be run:
# - Automatically via docker-compose zitadel-setup service
# - Manually: ./docker/zitadel/setup.sh
#
# Idempotent: skips if already configured

set -e

# Configuration - can be overridden by environment
ZITADEL_URL="${ZITADEL_URL:-http://op-zitadel.dev.test:8080}"
AUTH_DIR="${AUTH_DIR:-$(dirname "$0")/../auth}"
PAT_FILE="${PAT_FILE:-$AUTH_DIR/admin.pat}"
CREDENTIALS_FILE="${CREDENTIALS_FILE:-$AUTH_DIR/zitadel-credentials.env}"

# Logging
log() { echo "[Zitadel Setup] $1"; }
warn() { echo "[Zitadel Setup] WARNING: $1" >&2; }
error() { echo "[Zitadel Setup] ERROR: $1" >&2; exit 1; }

# Check if already configured
check_existing() {
  if [ -f "$CREDENTIALS_FILE" ]; then
    CLIENT_ID=$(grep "^ZITADEL_IDP_CLIENT_ID=" "$CREDENTIALS_FILE" 2>/dev/null | cut -d= -f2)
    if [ -n "$CLIENT_ID" ] && [ "$CLIENT_ID" != "placeholder" ]; then
      log "Already configured (Client ID: $CLIENT_ID)"
      log "To reconfigure, delete $CREDENTIALS_FILE and run again"
      exit 0
    fi
  fi
}

# Wait for PAT file
wait_for_pat() {
  log "Waiting for admin PAT file at $PAT_FILE..."
  timeout=120
  while [ ! -f "$PAT_FILE" ] || [ ! -s "$PAT_FILE" ]; do
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
      error "Timeout waiting for $PAT_FILE - is Zitadel running?"
    fi
    sleep 1
  done
  log "Found PAT file"
}

# Wait for Zitadel API
wait_for_api() {
  log "Waiting for Zitadel API at $ZITADEL_URL..."
  timeout=60
  while ! curl -sf "$ZITADEL_URL/debug/ready" >/dev/null 2>&1; do
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
      error "Timeout waiting for Zitadel API"
    fi
    sleep 1
  done
  log "Zitadel API is ready"
}

# API helper
api() {
  method="$1"
  endpoint="$2"
  data="$3"

  if [ -n "$data" ]; then
    curl -sf -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data" \
      "$ZITADEL_URL$endpoint" 2>/dev/null || echo "{}"
  else
    curl -sf -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      "$ZITADEL_URL$endpoint" 2>/dev/null || echo "{}"
  fi
}

# Extract JSON field (simple sed-based extraction)
json_field() {
  echo "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" | head -1
}

main() {
  log "Starting Zitadel setup..."

  check_existing
  wait_for_pat
  wait_for_api

  TOKEN=$(cat "$PAT_FILE" | tr -d '\n')

  # Get organization ID
  log "Getting organization ID..."
  ORG_RESPONSE=$(api GET "/management/v1/orgs/me")
  ORG_ID=$(json_field "$ORG_RESPONSE" "id")
  log "Organization ID: $ORG_ID"

  # Create or find project
  log "Creating project 'Open Path'..."
  PROJECT_RESPONSE=$(api POST "/management/v1/projects" '{"name": "Open Path"}')
  PROJECT_ID=$(json_field "$PROJECT_RESPONSE" "id")

  if [ -z "$PROJECT_ID" ]; then
    log "Project may exist, searching..."
    SEARCH_RESPONSE=$(api POST "/management/v1/projects/_search" \
      '{"queries": [{"nameQuery": {"name": "Open Path", "method": "TEXT_QUERY_METHOD_EQUALS"}}]}')
    PROJECT_ID=$(json_field "$SEARCH_RESPONSE" "id")
  fi

  if [ -z "$PROJECT_ID" ]; then
    error "Failed to create or find project"
  fi
  log "Project ID: $PROJECT_ID"

  # Create Dex OIDC application
  log "Creating Dex OIDC application..."
  APP_DATA='{
    "name": "Dex IDP",
    "redirectUris": ["https://dex.dev.test/dex/callback", "http://dex.dev.test:4443/dex/callback"],
    "postLogoutRedirectUris": ["https://hmis-warehouse.dev.test/oauth2/sign_out", "https://hmis.dev.test/oauth2/sign_out", "http://localhost:3000"],
    "responseTypes": ["OIDC_RESPONSE_TYPE_CODE"],
    "grantTypes": ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE", "OIDC_GRANT_TYPE_REFRESH_TOKEN"],
    "appType": "OIDC_APP_TYPE_WEB",
    "authMethodType": "OIDC_AUTH_METHOD_TYPE_BASIC",
    "accessTokenType": "OIDC_TOKEN_TYPE_JWT",
    "idTokenRoleAssertion": true,
    "idTokenUserinfoAssertion": true,
    "devMode": true
  }'

  APP_RESPONSE=$(api POST "/management/v1/projects/$PROJECT_ID/apps/oidc" "$APP_DATA")
  CLIENT_ID=$(json_field "$APP_RESPONSE" "clientId")
  CLIENT_SECRET=$(json_field "$APP_RESPONSE" "clientSecret")

  if [ -z "$CLIENT_ID" ]; then
    log "App may exist, checking..."
    # Use POST search endpoint, not GET
    APPS_RESPONSE=$(api POST "/management/v1/projects/$PROJECT_ID/apps/_search" '{}')
    # clientId is nested in oidcConfig
    CLIENT_ID=$(echo "$APPS_RESPONSE" | sed -n 's/.*"clientId":"\([^"]*\)".*/\1/p' | head -1)
    if [ -n "$CLIENT_ID" ]; then
      log "Found existing app with Client ID: $CLIENT_ID"
      warn "App exists but secret not available. Regenerate in Zitadel console if needed."
      CLIENT_SECRET="EXISTING_APP_SECRET_NOT_AVAILABLE"
    fi
  fi

  if [ -z "$CLIENT_ID" ]; then
    error "Failed to create or find application"
  fi
  log "Client ID: $CLIENT_ID"

  # Create Rails service user
  log "Creating Rails service user..."
  USER_DATA='{"userName": "rails-app", "name": "Rails Application"}'
  USER_RESPONSE=$(api POST "/management/v1/users/machine" "$USER_DATA")
  RAILS_USER_ID=$(json_field "$USER_RESPONSE" "userId")

  if [ -z "$RAILS_USER_ID" ]; then
    log "Service user may exist, searching..."
    SEARCH_RESPONSE=$(api POST "/management/v1/users/_search" \
      '{"queries": [{"userNameQuery": {"userName": "rails-app", "method": "TEXT_QUERY_METHOD_EQUALS"}}]}')
    RAILS_USER_ID=$(json_field "$SEARCH_RESPONSE" "id")
  fi

  if [ -n "$RAILS_USER_ID" ]; then
    log "Service User ID: $RAILS_USER_ID"

    # Add IAM_OWNER role to the service user
    log "Adding IAM roles to service user..."
    api POST "/admin/v1/members" "{\"userId\": \"$RAILS_USER_ID\", \"roles\": [\"IAM_OWNER\"]}" >/dev/null 2>&1 || true

    # Create PAT for the service user
    log "Creating PAT for service user..."
    PAT_RESPONSE=$(api POST "/management/v1/users/$RAILS_USER_ID/pats" '{"expirationDate": "2035-01-01T00:00:00Z"}')
    SERVICE_TOKEN=$(json_field "$PAT_RESPONSE" "token")

    if [ -z "$SERVICE_TOKEN" ]; then
      warn "Could not create PAT (user may already have one). Check Zitadel console."
      SERVICE_TOKEN="CREATE_MANUALLY_IN_ZITADEL_CONSOLE"
    fi
  else
    warn "Could not create service user"
    RAILS_USER_ID=""
    SERVICE_TOKEN=""
  fi

  # Write credentials file
  log "Writing credentials to $CREDENTIALS_FILE..."
  cat > "$CREDENTIALS_FILE" << EOF
# Zitadel credentials - auto-generated
# Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
#
# Used by:
# - docker/auth/dev.dex.yaml (OIDC connector for Zitadel)
# - Rails app (for user provisioning API)

ZITADEL_ORG_ID=$ORG_ID
ZITADEL_IDP_CLIENT_ID=$CLIENT_ID
ZITADEL_IDP_CLIENT_SECRET=$CLIENT_SECRET
ZITADEL_API_URL=$ZITADEL_URL
ZITADEL_SERVICE_USER_TOKEN=$SERVICE_TOKEN
EOF

  log "Setup complete!"
  log ""
  log "Zitadel Console: $ZITADEL_URL/ui/console"
  log "Admin login: admin@openpath.op-zitadel.dev.test / AdminPassword1!"
}

main "$@"
