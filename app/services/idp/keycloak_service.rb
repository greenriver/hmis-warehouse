###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/developer/keycloak-idp.md
require 'net/http'
require 'json'

module Idp
  # Keycloak IDP service over the Admin REST API.
  #
  # Authenticates via OAuth2 client_credentials. Initialized with a config hash
  # (from Idp::ServiceConfig) or falls back to ENV. Required config keys: api_url,
  # realm, client_id, client_secret. There is no realm default — a blank realm
  # raises, so it must be configured explicitly (DB config or KEYCLOAK_REALM).
  class KeycloakService < Service
    UPDATABLE_ATTRIBUTES = [:first_name, :last_name, :email].freeze

    # Where Keycloak parks an unconfirmed address (`UserModel.EMAIL_PENDING`). It clears the attribute
    # on confirmation.
    EMAIL_PENDING_ATTRIBUTE = 'kc.email.pending'

    # Most calls are on a request path, so the default budget is short enough that a hung Keycloak
    # fails the request rather than holding the thread. Opening the socket doesn't get slower with a
    # bigger body, so there's one open timeout for everyone.
    OPEN_TIMEOUT_SECONDS = 2
    IO_TIMEOUT_SECONDS = 3

    # For the two calls that move more than a status code: the paginated user listing (#each_user)
    # and the bulk user import (#partial_import). Requested at the call site.
    BULK_IO_TIMEOUT_SECONDS = 30

    def initialize(config: nil)
      super(config: config || default_config)
      validate_config!
      @cached_token = nil
      @token_expires_at = nil
    end

    def self.from_config(config)
      new(config: {
            api_url: config.api_url,
            client_id: config.client_id,
            client_secret: config.service_token,
            realm: config.keycloak_realm,
          })
    end

    # @return [Hash] { success: Boolean, connector_user_id: String|nil }
    def create_user(email:, first_name:, last_name:, phone: nil) # rubocop:disable Lint/UnusedMethodArgument
      user_data = {
        username: email,
        email: email,
        firstName: first_name,
        lastName: last_name,
        enabled: true,
        emailVerified: false,
      }

      response = make_request(:post, "/admin/realms/#{realm}/users", body: user_data)

      handle_response(response, operation: :create_user, failure: 'Failed to create user') do |resp|
        user_id = resp['Location']&.split('/')&.last
        {
          success: true,
          connector_user_id: user_id,
        }
      end
    end

    def update_user(user_id:, attributes:)
      unknown = attributes.keys - UPDATABLE_ATTRIBUTES
      raise ArgumentError, "Unknown attributes: #{unknown.join(', ')}" if unknown.any?

      patch = {}
      patch['firstName'] = attributes[:first_name] if attributes[:first_name]
      patch['lastName'] = attributes[:last_name] if attributes[:last_name]

      email_changed = attributes[:email].present?
      if email_changed
        # The realm runs email-as-username, so Keycloak keeps username in step with email
        # on its own — we only send the email.
        patch['email'] = attributes[:email]
        patch['emailVerified'] = false
      end

      return true if patch.empty?

      result = put_full_user(user_id: user_id, patch: patch, operation: :update_user, failure: 'Failed to update user')
      if email_changed
        # Keycloak already holds the new address, so a mail failure must not fail the update: the
        # caller would roll its local write back and leave the two out of step in the other
        # direction, with no retry that could close the gap.
        begin
          send_execute_actions_email(user_id: user_id, actions: ['VERIFY_EMAIL'])
        rescue ServiceError => e
          Sentry.capture_exception_with_info(e, "Updated #{user_id} in #{idp_name}, but couldn't send the address verification email")
        end
      end
      result
    end

    # @return [Hash, nil] the matching UserRepresentation, or nil if no user has this email.
    def find_user_by_email(email:)
      query = URI.encode_www_form(email: email, exact: true)
      response = make_request(:get, "/admin/realms/#{realm}/users?#{query}")

      handle_response(response, operation: :find_user_by_email, failure: 'Failed to look up user by email') do |resp|
        Array(JSON.parse(resp.body)).first
      end
    end

    # Trigger Keycloak's execute-actions email so the user completes `actions` (e.g.
    # setting a password, verifying their email) via a link rather than the admin setting
    # a credential. Requires SMTP configured on the realm; a mail failure surfaces as a
    # ServiceError with a delivery-focused, user-facing message. Returns true on the 204.
    def send_execute_actions_email(user_id:, actions:)
      response = make_request(:put, "/admin/realms/#{realm}/users/#{user_id}/execute-actions-email", body: actions)
      return true if (200..299).include?(response.code.to_i)

      # This endpoint's only job is to send mail, so any non-2xx means delivery failed. Keycloak
      # reports an undeliverable address and an unconfigured/failing SMTP setup alike as a 500, so
      # skip handle_response's raw status code and give the admin something actionable
      Rails.logger.warn("Keycloak execute-actions-email failed (#{response.code}): #{error_message_from(response)}")
      raise ServiceError.new(
        "we couldn't deliver it. Please check that email address is valid",
        idp_name: idp_name,
        operation: :send_execute_actions_email,
      )
    end

    # Yield every user in the realm as { email:, id: }, paging explicitly through
    # the Admin API. Used by the backfill to build one email => id map instead of
    # a GET-per-user. Do NOT replace with an unpaginated GET /users: Keycloak
    # silently caps the response (default 100), so a single call quietly drops
    # every user past the first page.
    def each_user(page_size: 100)
      return enum_for(:each_user, page_size: page_size) unless block_given?

      first = 0
      loop do
        response = make_request(:get, "/admin/realms/#{realm}/users?first=#{first}&max=#{page_size}", io_timeout: BULK_IO_TIMEOUT_SECONDS)
        users = handle_response(response, operation: :each_user, failure: 'Failed to list users') do |resp|
          JSON.parse(resp.body)
        end

        users.each { |u| yield({ email: u['email'], id: u['id'] }) }

        # A short (or empty) page is the last one.
        break if users.size < page_size

        first += page_size
      end
    end

    def get_user(user_id:)
      response = make_request(:get, "/admin/realms/#{realm}/users/#{user_id}")

      if response.code.to_i == 404
        raise ServiceError.new(
          "User not found: #{user_id}",
          idp_name: idp_name,
          operation: :get_user,
        )
      end

      handle_response(response, operation: :get_user, failure: 'Failed to get user') do |resp|
        JSON.parse(resp.body)
      end
    end

    # Read only — Keycloak owns the attribute's lifecycle.
    def pending_email(user_id:)
      representation = get_user(user_id: user_id)
      Array(representation.dig('attributes', EMAIL_PENDING_ATTRIBUTE)).first.presence
    end

    def reactivate_user(user_id:)
      put_full_user(user_id: user_id, patch: { 'enabled' => true }, operation: :reactivate_user, failure: 'Failed to reactivate user')
    end

    # Disable the account in Keycloak. Mirror of #reactivate_user
    def deactivate_user(user_id:)
      put_full_user(user_id: user_id, patch: { 'enabled' => false }, operation: :deactivate_user, failure: 'Failed to deactivate user')
    end

    # Ends every session this user has in the realm, other browsers and devices included. Their SSO
    # cookie stays in the browser but is dead, so the next request re-prompts.
    # Back channel because Dex won't propagate a logout upstream — see
    # Idp::JwtAuthentication#idp_end_token_holder_sessions.
    def logout_user_sessions(user_id:)
      response = make_request(:post, "/admin/realms/#{realm}/users/#{user_id}/logout")

      handle_response(response, operation: :logout_user_sessions, failure: 'Failed to end IDP sessions') { true }
    end

    # Set Keycloak required actions the user must complete at next login (e.g.
    # ['UPDATE_PASSWORD'] to force a password change).
    def set_required_action(user_id:, actions:)
      put_full_user(user_id: user_id, patch: { 'requiredActions' => actions }, operation: :set_required_action, failure: 'Failed to set required actions')
    end

    def idp_name
      'Keycloak'
    end

    def supports_user_management?
      true
    end

    def supports_profile_updates?
      true
    end

    # Asserted, not probed: the Update Email required action and realm Verify Email are operator
    # prerequisites documented in docs/developer/keycloak-idp.md, not something checked at render
    # time. An Admin-API probe would only buy graceful degradation on realms Open Path does not
    # administer; this predicate is where one would go.
    def supports_email_self_service?
      true
    end

    def supports_user_creation?
      true
    end

    def supports_account_backfill?
      true
    end

    # The endpoint exists on every realm, so the only question is whether this service points at
    # one — same reading of a blank api_url as browser_url. Unlike the other predicates here, this
    # one gates sign-out, and the caller fails closed: answering true for a connector we can't
    # reach would refuse sign-out for everyone on it, over a session we were never holding. Whether
    # the service account may call it (manage-users, granted separately from the user read/write
    # calls) is ops config and still shows up as a failure.
    def supports_session_logout?
      api_url.present?
    end

    # Deep-link to the Keycloak Account Console for this realm, where end users
    # manage their own password and 2FA.
    def account_console_url
      return nil unless browser_url.present?

      "#{browser_url}/realms/#{realm}/account"
    end

    # Keycloak Application-Initiated Action: sends the browser through the realm's OIDC
    # authorize endpoint with kc_action set, so the user completes exactly one action
    # (password change, TOTP setup, ...) against their existing Keycloak SSO session and
    # is redirected back to redirect_uri. Only usable for the current user — it runs
    # against whoever's browser session it is, not an arbitrary user_id.
    #
    # The redirect_uri must be registered under this client's Valid Redirect URIs in
    # Keycloak, and the client must have the standard (authorization code) flow enabled.
    #
    # redirect_uri only governs the return after the *form* is submitted. UPDATE_EMAIL has a second
    # leg — the confirmation link mailed to the new address — which returns via the client's Base URL
    # instead, so see #account_client_id too.
    def account_action_url(action:, redirect_uri:)
      return nil unless browser_url.present?

      params = {
        client_id: account_client_id,
        redirect_uri: redirect_uri,
        response_type: 'code',
        scope: 'openid',
        kc_action: action,
      }
      "#{browser_url}/realms/#{realm}/protocol/openid-connect/auth?#{params.to_query}"
    end

    # Ping the Admin API to verify credentials and connectivity, using the same
    # users endpoint the rest of the class relies on so this reflects the
    # permissions the service account actually needs.
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      response = make_request(:get, "/admin/realms/#{realm}/users?max=1")

      case response.code.to_i
      when 200..299
        {
          success: true,
          message: 'Connection successful to Keycloak',
        }
      when 401, 403
        {
          success: false,
          message: 'Authentication failed: Invalid credentials or insufficient permissions',
        }
      when 404
        {
          success: false,
          message: 'API endpoint not found: Check API URL and realm are correct',
        }
      when 500..599
        {
          success: false,
          message: "Keycloak server error: #{response.code}",
        }
      else
        {
          success: false,
          message: "Connection failed: #{error_message_from(response)}",
        }
      end
    rescue Errno::ECONNREFUSED
      {
        success: false,
        message: "Connection refused: Unable to reach Keycloak at #{api_url}",
      }
    rescue Errno::EHOSTUNREACH
      {
        success: false,
        message: "Host unreachable: Check API URL is correct (#{api_url})",
      }
    rescue Timeout::Error
      {
        success: false,
        message: 'Connection timeout: Keycloak is not responding',
      }
    rescue StandardError => e
      {
        success: false,
        message: "Connection error: #{e.message}",
      }
    end

    # Used by the migration tooling; remove once Devise account data has been migrated.
    def partial_import(import_data)
      make_request(:post, "/admin/realms/#{realm}/partialImport", body: import_data, io_timeout: BULK_IO_TIMEOUT_SECONDS)
    end

    private

    def validate_config!
      missing = [:api_url, :realm, :client_id, :client_secret].select { |key| config[key].blank? }
      return if missing.empty?

      raise ServiceError.new(
        "Keycloak misconfigured, missing: #{missing.join(', ')}",
        idp_name: 'Keycloak',
        operation: :initialize,
      )
    end

    def api_url
      config[:api_url]
    end

    # Base URL for links we hand to a browser instead of fetching ourselves. Same host as the
    # Admin API except in dev, where containers talk to Keycloak directly but the browser goes
    # through Traefik, and the deep-links need the origin that owns the SSO session cookies.
    #
    # ENV because it describes a deployment's network rather than a realm; add an
    # Idp::ServiceConfig column if some deployment needs it per realm.
    def browser_url
      # no api_url means the service isn't configured, so there's nothing browser-facing either
      return nil if api_url.blank?

      config[:browser_url].presence || ENV['KEYCLOAK_PUBLIC_URL'].presence || api_url
    end

    # The OIDC client an application-initiated action (AIA) runs under
    def account_client_id
      config[:account_client_id].presence || ENV['KEYCLOAK_ACCOUNT_CLIENT_ID'].presence || 'account'
    end

    def realm
      config[:realm]
    end

    def client_id
      config[:client_id]
    end

    def client_secret
      config[:client_secret]
    end

    # Return a valid access token, fetching a new one if expired or not yet obtained.
    def access_token
      now = Time.current
      if @cached_token.nil? || now >= @token_expires_at
        token_response = fetch_token
        @cached_token = token_response['access_token']
        expires_in = token_response['expires_in'].to_i
        @token_expires_at = now + expires_in - 30
      end
      @cached_token
    end

    # `io_timeout` overrides the read and write budget for a caller that needs longer than the
    # default — see BULK_IO_TIMEOUT_SECONDS.
    def build_http(uri, io_timeout: IO_TIMEOUT_SECONDS)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = OPEN_TIMEOUT_SECONDS
      http.read_timeout = io_timeout
      http.write_timeout = io_timeout
      http
    end

    def fetch_token
      uri = URI("#{api_url}/realms/#{realm}/protocol/openid-connect/token")
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(
        grant_type: 'client_credentials',
        client_id: client_id,
        client_secret: client_secret,
      )

      response = http.request(request)

      unless (200..299).include?(response.code.to_i)
        raise ServiceError.new(
          "Failed to obtain access token: #{response.code}",
          idp_name: idp_name,
          operation: :access_token,
        )
      end

      JSON.parse(response.body)
    end

    # Make an authenticated request to the Keycloak Admin API, retrying once on 401.
    def make_request(method, path, body: nil, io_timeout: IO_TIMEOUT_SECONDS, token_retried: false)
      uri = URI("#{api_url}#{path}")
      http = build_http(uri, io_timeout: io_timeout)

      request_class =
        case method
        when :get    then Net::HTTP::Get
        when :post   then Net::HTTP::Post
        when :put    then Net::HTTP::Put
        when :delete then Net::HTTP::Delete
        else raise ArgumentError, "Unsupported HTTP method: #{method}"
        end

      request = request_class.new(uri.request_uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      request.body = body.to_json if body

      response = http.request(request)

      if response.code.to_i == 401 && !token_retried
        @cached_token = nil
        @token_expires_at = nil
        return make_request(method, path, body: body, io_timeout: io_timeout, token_retried: true)
      end

      response
    end

    # Interpret a Keycloak Admin API response: yield the response on 2xx and
    # return the block's value, otherwise raise a ServiceError tagged with the
    # operation. `failure` is the verb used in the 4xx message. 409 gets the
    # ConflictError subclass so callers can tell "this email is taken over there"
    # from "the connector is broken".
    def handle_response(response, operation:, failure:)
      case response.code.to_i
      when 200..299
        yield(response)
      when 409
        raise ConflictError.new(
          "#{failure}: #{error_message_from(response)}",
          idp_name: idp_name,
          operation: operation,
        )
      when 400..499
        raise ServiceError.new(
          "#{failure}: #{error_message_from(response)}",
          idp_name: idp_name,
          operation: operation,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Keycloak: #{response.code}",
          idp_name: idp_name,
          operation: operation,
        )
      end
    end

    def error_message_from(response)
      data = JSON.parse(response.body)
      data['errorMessage'] || data['error_description'] || data['error'] || response.body
    rescue StandardError
      response.body
    end

    # Keycloak's PUT /users/{id} replaces the full representation (v24+ full-replace semantics) —
    # any field left out of the body is cleared, not left alone. Fetch the current representation
    # and merge the patch onto it so untouched fields (attributes, username, other requiredActions,
    # etc.) survive the write.
    #
    # This is a read-modify-write with no optimistic locking (Keycloak's PUT has no If-Match), so
    # a write that overlaps another can clobber it from a stale GET. The admin surface drives these
    # sequentially per request, so overlap is not expected; revisit if a concurrent caller appears.
    def put_full_user(user_id:, patch:, operation:, failure:)
      current = get_user(user_id: user_id)
      response = make_request(:put, "/admin/realms/#{realm}/users/#{user_id}", body: current.merge(patch))

      handle_response(response, operation: operation, failure: failure) { true }
    end

    protected

    def default_config
      {
        api_url: ENV['KEYCLOAK_API_URL'],
        browser_url: ENV['KEYCLOAK_PUBLIC_URL'],
        account_client_id: ENV['KEYCLOAK_ACCOUNT_CLIENT_ID'],
        realm: ENV['KEYCLOAK_REALM'],
        client_id: ENV['KEYCLOAK_SERVICE_CLIENT_ID'],
        client_secret: ENV['KEYCLOAK_SERVICE_CLIENT_SECRET'],
      }
    end
  end
end
