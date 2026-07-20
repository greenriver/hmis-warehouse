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
            skip_ssl_verification: config.skip_ssl_verification,
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

      updates = {}
      updates[:firstName] = attributes[:first_name] if attributes[:first_name]
      updates[:lastName] = attributes[:last_name] if attributes[:last_name]

      if attributes[:email]
        updates[:email] = attributes[:email]
        updates[:emailVerified] = false
      end

      return true if updates.empty?

      response = make_request(:put, "/admin/realms/#{realm}/users/#{user_id}", body: updates)

      handle_response(response, operation: :update_user, failure: 'Failed to update user') { true }
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

    def reactivate_user(user_id:)
      response = make_request(
        :put,
        "/admin/realms/#{realm}/users/#{user_id}",
        body: { enabled: true },
      )

      handle_response(response, operation: :reactivate_user, failure: 'Failed to reactivate user') { true }
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

    # Deep-link to the Keycloak Account Console for this realm, where end users
    # manage their own password and 2FA. Built from the browser-reachable
    # api_url, consistent with logout_url.
    def account_console_url
      return nil unless api_url.present?

      "#{api_url}/realms/#{realm}/account"
    end

    # Ping the Admin API to verify credentials and connectivity.
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      response = make_request(:get, "/admin/realms/#{realm}")

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

    def logout_url(post_logout_redirect_uri:, client_id: nil)
      return post_logout_redirect_uri unless api_url.present?

      params = { post_logout_redirect_uri: post_logout_redirect_uri }
      params[:client_id] = client_id if client_id.present?

      "#{api_url}/realms/#{realm}/protocol/openid-connect/logout?#{params.to_query}"
    end

    # Used by the migration tooling; remove once Devise account data has been migrated.
    def partial_import(import_data)
      make_request(:post, "/admin/realms/#{realm}/partialImport", body: import_data)
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
      if @cached_token.nil? || Time.current >= @token_expires_at
        token_response = fetch_token
        @cached_token = token_response['access_token']
        expires_in = token_response['expires_in'].to_i
        @token_expires_at = now + expires_in - 30
      end
      @cached_token
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      # Some non-production Keycloak instances use self-signed certificates.
      # Opt out of verification only when the config explicitly requests it.
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && skip_ssl_verification?
      http.open_timeout = 10
      http.read_timeout = 30
      http
    end

    # When true, TLS certificate verification is disabled for Keycloak requests.
    # Intended for staging/dev environments with self-signed certificates only.
    def skip_ssl_verification?
      ActiveModel::Type::Boolean.new.cast(config[:skip_ssl_verification])
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
    def make_request(method, path, body: nil, token_retried: false)
      uri = URI("#{api_url}#{path}")
      http = build_http(uri)

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
        return make_request(method, path, body: body, token_retried: true)
      end

      response
    end

    # Interpret a Keycloak Admin API response: yield the response on 2xx and
    # return the block's value, otherwise raise a ServiceError tagged with the
    # operation. `failure` is the verb used in the 4xx message.
    def handle_response(response, operation:, failure:)
      case response.code.to_i
      when 200..299
        yield(response)
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

    protected

    def default_config
      {
        api_url: ENV['KEYCLOAK_API_URL'],
        realm: ENV['KEYCLOAK_REALM'],
        client_id: ENV['KEYCLOAK_SERVICE_CLIENT_ID'],
        client_secret: ENV['KEYCLOAK_SERVICE_CLIENT_SECRET'],
      }
    end
  end
end
