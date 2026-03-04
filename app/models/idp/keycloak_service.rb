###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/developer/keycloak-idp.md
require 'net/http'
require 'json'

module Idp
  # Keycloak IDP service implementation.
  #
  # Provides user management operations for Keycloak IDP using the Admin REST API.
  # Uses OAuth2 client_credentials flow for authentication (no PAT required).
  # Can be initialized with a config hash (from Idp::ServiceConfig) or will use ENV variables as fallback.
  #
  # Config hash keys:
  # - api_url: Base URL for Keycloak (e.g., http://op-keycloak.dev.test:8080)
  # - realm: Keycloak realm name (default: 'openpath')
  # - client_id: Service account client ID with manage-users permission
  # - client_secret: Service account client secret
  class KeycloakService < Service
    def initialize(config: nil)
      super(config: config || default_config)
      @cached_token = nil
      @token_expires_at = nil
    end

    # Create a new user in Keycloak.
    #
    # @param email [String] User's email address
    # @param first_name [String] User's first name
    # @param last_name [String] User's last name
    # @param phone [String, nil] User's phone number (unused; Keycloak does not support phone in this flow)
    # @return [Hash] Result hash with :success (Boolean) and :connector_user_id (String, nil)
    #   Example: { success: true, connector_user_id: 'uuid-123' }
    # @raise [Idp::ServiceError] if user creation fails
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

      case response.code.to_i
      when 201
        location = response['Location']
        user_id = location&.split('/')&.last
        {
          success: true,
          connector_user_id: user_id,
        }
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to create user: #{error_data['errorMessage'] || response.body}",
          idp_name: idp_name,
          operation: :create_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Keycloak: #{response.code}",
          idp_name: idp_name,
          operation: :create_user,
        )
      end
    end

    # Update a user's profile in Keycloak.
    #
    # @param user_id [String] Keycloak user ID
    # @param attributes [Hash] Hash of attributes to update (e.g., { first_name: 'John', email: 'john@example.com' })
    # @return [Boolean] true if successful
    # @raise [Idp::ServiceError] if update fails
    def update_user(user_id:, attributes:)
      updates = {}
      updates[:firstName] = attributes[:first_name] if attributes[:first_name]
      updates[:lastName] = attributes[:last_name] if attributes[:last_name]

      if attributes[:email]
        updates[:email] = attributes[:email]
        updates[:emailVerified] = false
      end

      return {} if updates.empty?

      response = make_request(:put, "/admin/realms/#{realm}/users/#{user_id}", body: updates)

      case response.code.to_i
      when 200..299
        true
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to update user: #{error_data['errorMessage'] || response.body}",
          idp_name: idp_name,
          operation: :update_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Keycloak: #{response.code}",
          idp_name: idp_name,
          operation: :update_user,
        )
      end
    end

    # Fetch user data from Keycloak.
    #
    # @param user_id [String] Keycloak user ID
    # @return [Hash] User data
    # @raise [Idp::ServiceError] if user not found
    def get_user(user_id:)
      response = make_request(:get, "/admin/realms/#{realm}/users/#{user_id}")

      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 404
        raise ServiceError.new(
          "User not found: #{user_id}",
          idp_name: idp_name,
          operation: :get_user,
        )
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to get user: #{error_data['errorMessage'] || response.body}",
          idp_name: idp_name,
          operation: :get_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Keycloak: #{response.code}",
          idp_name: idp_name,
          operation: :get_user,
        )
      end
    end

    # Reactivate a user account in Keycloak by enabling them.
    #
    # @param user_id [String] Keycloak user ID
    # @return [Boolean] true if successful
    # @raise [Idp::ServiceError] if reactivation fails
    def reactivate_user(user_id:)
      response = make_request(
        :put,
        "/admin/realms/#{realm}/users/#{user_id}",
        body: { enabled: true },
      )

      case response.code.to_i
      when 200..299
        true
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to reactivate user: #{error_data['errorMessage'] || response.body}",
          idp_name: idp_name,
          operation: :reactivate_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Keycloak: #{response.code}",
          idp_name: idp_name,
          operation: :reactivate_user,
        )
      end
    end

    # Return human-readable name for Keycloak.
    #
    # @return [String] "Keycloak"
    def idp_name
      'Keycloak'
    end

    # Check if Keycloak supports user management operations.
    #
    # @return [Boolean] true if API URL, client ID, and client secret are all configured
    def supports_user_management?
      api_url.present? && client_id.present? && client_secret.present?
    end

    # Check if Keycloak supports profile field updates.
    #
    # @return [Boolean] true
    def supports_profile_updates?
      true
    end

    # Test connection to Keycloak Admin API.
    #
    # Makes a GET request to the realm endpoint to verify credentials and connectivity.
    #
    # @return [Hash] Result hash with :success (Boolean) and optional :message (String)
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
        begin
          error_data = JSON.parse(response.body)
          message = error_data['error_description'] || error_data['error'] || response.body
        rescue StandardError
          message = response.body
        end
        {
          success: false,
          message: "Connection failed: #{message}",
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

    # Generate OIDC RP-Initiated Logout URL for Keycloak.
    #
    # @param post_logout_redirect_uri [String] Where to redirect after logout
    # @param client_id [String, nil] Optional client_id parameter
    # @return [String] Logout URL, or post_logout_redirect_uri if api_url is blank
    def logout_url(post_logout_redirect_uri:, client_id: nil)
      return post_logout_redirect_uri unless api_url.present?

      params = { post_logout_redirect_uri: post_logout_redirect_uri }
      params[:client_id] = client_id if client_id.present?

      "#{api_url}/realms/#{realm}/protocol/openid-connect/logout?#{params.to_query}"
    end

    # Build user data structure for Keycloak partial import.
    #
    # Includes password and TOTP credentials in Keycloak's credential format.
    #
    # @param user [User] User object from Rails app
    # @return [Hash] User data in Keycloak partialImport format
    def build_import_user_data(user)
      groups = []
      groups << '/warehouse-users' if user.login_to?(:warehouse)
      groups << '/hmis-users' if user.login_to?(:hmis)

      {
        username: user.email,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        enabled: true,
        emailVerified: user.confirmed_at.present?,
        groups: groups,
        credentials: [
          build_password_data(user),
          build_otp_credential(user),
        ].compact,
      }
    end

    # Bulk import multiple users to Keycloak via partialImport API.
    #
    # @param users [Array<User>] Array of User objects to import
    # @param policy [String] Conflict policy: 'SKIP', 'OVERWRITE', or 'FAIL' (default: 'SKIP')
    # @return [Hash] Result with :success (Boolean), :imported_count (Integer), and optional :error (String)
    def bulk_import_users(users, policy: 'SKIP')
      import_data = {
        ifResourceExists: policy,
        users: users.map { |user| build_import_user_data(user) },
      }

      response = make_request(:post, "/admin/realms/#{realm}/partialImport", body: import_data)

      case response.code.to_i
      when 200..299
        {
          success: true,
          imported_count: users.size,
          response: JSON.parse(response.body),
        }
      else
        begin
          error_data = JSON.parse(response.body)
          error_message = error_data['error'] || error_data['errorMessage'] || response.body
        rescue StandardError
          error_message = response.body
        end
        {
          success: false,
          error: "Import failed (#{response.code}): #{error_message}",
          failed_count: users.size,
        }
      end
    rescue StandardError => e
      {
        success: false,
        error: e.message,
        failed_count: users.size,
      }
    end

    # Export users to Keycloak partialImport format without making API call.
    #
    # @param users [Array<User>] Array of User objects to export
    # @return [Hash] Keycloak partialImport JSON structure
    def export_users_to_import_format(users)
      {
        ifResourceExists: 'SKIP',
        users: users.map { |user| build_import_user_data(user) },
      }
    end

    # Import users from JSON file using Keycloak partialImport API.
    #
    # @param file_path [String] Path to JSON file with partialImport data
    # @return [Hash] Result with :success (Boolean) and :response (Hash)
    # @raise [Idp::ServiceError] if file not found or import fails
    def import_from_file(file_path)
      raise Idp::ServiceError, "File not found: #{file_path}" unless File.exist?(file_path)

      import_data = JSON.parse(File.read(file_path))

      response = make_request(:post, "/admin/realms/#{realm}/partialImport", body: import_data)

      case response.code.to_i
      when 200..299
        {
          success: true,
          response: JSON.parse(response.body),
        }
      else
        begin
          error_data = JSON.parse(response.body)
          error_message = error_data['error'] || error_data['errorMessage'] || response.body
        rescue StandardError
          error_message = response.body
        end
        raise Idp::ServiceError.new(
          "Import failed (#{response.code}): #{error_message}",
          idp_name: idp_name,
          operation: :import_from_file,
        )
      end
    end

    private

    def api_url
      config[:api_url]
    end

    def realm
      config[:realm] || 'openpath'
    end

    def client_id
      config[:client_id]
    end

    def client_secret
      config[:client_secret]
    end

    # Return a valid access token, fetching a new one if expired or not yet obtained.
    def access_token
      if @cached_token.nil? || Time.now >= @token_expires_at
        token_response = fetch_token
        @cached_token = token_response['access_token']
        expires_in = token_response['expires_in'].to_i
        @token_expires_at = Time.now + expires_in - 30
      end
      @cached_token
    end

    # Fetch a new access token via client_credentials grant.
    def fetch_token
      uri = URI("#{api_url}/realms/#{realm}/protocol/openid-connect/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
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

    # Make an authenticated HTTP request to the Keycloak Admin API.
    #
    # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body (optional)
    # @return [Net::HTTPResponse] HTTP response
    def make_request(method, path, body: nil)
      uri = URI("#{api_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request_class =
        case method
        when :get
          Net::HTTP::Get
        when :post
          Net::HTTP::Post
        when :put
          Net::HTTP::Put
        when :delete
          Net::HTTP::Delete
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end

      request = request_class.new(uri.path)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      request.body = body.to_json if body

      http.request(request)
    end

    # Build Keycloak password credential from bcrypt hash.
    #
    # @param user [User] User object from Rails app
    # @return [Hash, nil] Password credential in Keycloak format, or nil if no password
    def build_password_data(user)
      return nil unless user.encrypted_password.present?

      {
        type: 'password',
        secretData: { value: user.encrypted_password, salt: '' }.to_json,
        credentialData: { hashIterations: 10, algorithm: 'bcrypt' }.to_json,
        temporary: false,
      }
    end

    # Build Keycloak TOTP credential from decrypted OTP secret.
    #
    # @param user [User] User object from Rails app
    # @return [Hash, nil] TOTP credential in Keycloak format, or nil if not applicable
    def build_otp_credential(user)
      return nil unless user.encrypted_otp_secret.present? && user.otp_required_for_login?

      begin
        otp_secret = user.otp_secret
      rescue StandardError => e
        Rails.logger.warn "Failed to decrypt OTP secret for #{user.email}: #{e.message}"
        return nil
      end

      return nil unless otp_secret

      {
        type: 'otp',
        secretData: { value: otp_secret }.to_json,
        # secretEncoding: 'BASE32' tells Keycloak to Base32-decode the stored value before
        # using it as the HMAC key. Without this, Keycloak uses raw UTF-8 bytes of the string,
        # which does not match what authenticator apps produce (they Base32-decode the secret
        # from the QR code). Devise stores secrets as Base32 strings, so this is required.
        credentialData: {
          subType: 'totp', digits: 6, counter: 0, period: 30, algorithm: 'HmacSHA1',
          secretEncoding: 'BASE32'
        }.to_json,
      }
    end

    protected

    def default_config
      {
        api_url: ENV['KEYCLOAK_API_URL'],
        realm: ENV.fetch('KEYCLOAK_REALM', 'openpath'),
        client_id: ENV['KEYCLOAK_SERVICE_CLIENT_ID'],
        client_secret: ENV['KEYCLOAK_SERVICE_CLIENT_SECRET'],
      }
    end
  end
end
