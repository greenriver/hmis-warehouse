###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/http'
require 'json'

module Idp
  # Zitadel IDP service implementation.
  #
  # Provides user management operations for Zitadel IDP using the Management API.
  # Can be initialized with a config hash (from Idp::ServiceConfig) or will use ENV variables as fallback.
  #
  # Config hash keys:
  # - api_url: Base URL for Zitadel API (e.g., http://zitadel.dev.test:8080)
  # - service_token: Personal Access Token with admin permissions
  # - org_id: Organization ID in Zitadel
  # - project_id: (Optional) Project ID for granting user access to the Warehouse application
  class ZitadelService < Service
    def initialize(config: nil)
      super(config: config || default_config)
    end

    # Create a new user in Zitadel.
    #
    # @param email [String] User's email address
    # @param first_name [String] User's first name
    # @param last_name [String] User's last name
    # @param phone [String, nil] User's phone number (optional)
    # @return [Hash] Result hash with :success (Boolean) and :connector_user_id (String, nil)
    #   Example: { success: true, connector_user_id: 'user-123' }
    # @raise [Idp::ServiceError] if user creation fails
    def create_user(email:, first_name:, last_name:, phone: nil)
      user_data = {
        userName: email,
        profile: {
          firstName: first_name,
          lastName: last_name,
          displayName: "#{first_name} #{last_name}",
          preferredLanguage: 'en',
        },
        email: {
          email: email,
          isEmailVerified: false,
        },
      }

      if phone.present?
        user_data[:phone] = {
          phone: phone,
          isPhoneVerified: false,
        }
      end

      response = make_request(:post, '/management/v1/users/human', body: user_data)

      case response.code.to_i
      when 200..299
        result = JSON.parse(response.body)
        # Grant user access to project if project_id is configured
        grant_project_access(result['userId']) if project_id.present? && result['userId']
        {
          success: true,
          connector_user_id: result['userId'],
        }
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to create user: #{error_data['message'] || response.body}",
          idp_name: idp_name,
          operation: :create_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Zitadel: #{response.code}",
          idp_name: idp_name,
          operation: :create_user,
        )
      end
    end

    # Update a user's profile in Zitadel.
    #
    # @param user_id [String] Zitadel user ID
    # @param attributes [Hash] Hash of attributes to update (e.g., { first_name: 'John', email: 'john@example.com' })
    # @return [Hash] Updated user data
    # @raise [Idp::ServiceError] if update fails
    def update_user(user_id:, attributes:)
      updates = {}

      if attributes[:first_name] || attributes[:last_name]
        updates[:profile] = {}
        updates[:profile][:firstName] = attributes[:first_name] if attributes[:first_name]
        updates[:profile][:lastName] = attributes[:last_name] if attributes[:last_name]
        updates[:profile][:displayName] = "#{attributes[:first_name] || ''} #{attributes[:last_name] || ''}".strip
      end

      if attributes[:email]
        updates[:email] = {
          email: attributes[:email],
          isEmailVerified: false,
        }
      end

      if attributes[:phone]
        updates[:phone] = {
          phone: attributes[:phone],
          isPhoneVerified: false,
        }
      end

      return {} if updates.empty?

      response = make_request(:put, "/management/v1/users/human/#{user_id}", body: updates)

      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 400..499
        begin
          error_data = JSON.parse(response.body)
        rescue StandardError
          error_data = {}
        end
        raise ServiceError.new(
          "Failed to update user: #{error_data['message'] || response.body}",
          idp_name: idp_name,
          operation: :update_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Zitadel: #{response.code}",
          idp_name: idp_name,
          operation: :update_user,
        )
      end
    end

    # Fetch user data from Zitadel.
    #
    # @param user_id [String] Zitadel user ID
    # @return [Hash] User data
    # @raise [Idp::ServiceError] if user not found
    def get_user(user_id:)
      response = make_request(:get, "/management/v1/users/human/#{user_id}")

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
          "Failed to get user: #{error_data['message'] || response.body}",
          idp_name: idp_name,
          operation: :get_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Zitadel: #{response.code}",
          idp_name: idp_name,
          operation: :get_user,
        )
      end
    end

    # Reactivate a user account in Zitadel.
    #
    # @param user_id [String] Zitadel user ID
    # @return [Boolean] true if successful
    # @raise [Idp::ServiceError] if reactivation fails
    def reactivate_user(user_id:)
      response = make_request(:post, "/management/v1/users/human/#{user_id}/reactivate")

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
          "Failed to reactivate user: #{error_data['message'] || response.body}",
          idp_name: idp_name,
          operation: :reactivate_user,
        )
      else
        raise ServiceError.new(
          "Unexpected response from Zitadel: #{response.code}",
          idp_name: idp_name,
          operation: :reactivate_user,
        )
      end
    end

    # Return human-readable name for Zitadel.
    #
    # @return [String] "Zitadel"
    def idp_name
      'Zitadel'
    end

    # Check if Zitadel supports user management operations.
    #
    # @return [Boolean] true if API URL and token are configured
    def supports_user_management?
      api_url.present? && token.present?
    end

    # Check if Zitadel supports profile field updates.
    #
    # @return [Boolean] true
    def supports_profile_updates?
      true
    end

    # Test connection to Zitadel API.
    #
    # Makes a simple API call to verify credentials and connectivity.
    #
    # @return [Hash] Result hash with :success (Boolean) and optional :message (String)
    def test_connection
      response = make_request(:get, '/management/v1/orgs/me')

      case response.code.to_i
      when 200..299
        {
          success: true,
          message: 'Connection successful to Zitadel',
        }
      when 401, 403
        {
          success: false,
          message: 'Authentication failed: Invalid token or insufficient permissions',
        }
      when 404
        {
          success: false,
          message: 'API endpoint not found: Check API URL is correct',
        }
      when 500..599
        {
          success: false,
          message: "Zitadel server error: #{response.code}",
        }
      else
        begin
          error_data = JSON.parse(response.body)
          message = error_data['message'] || error_data['error'] || response.body
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
        message: "Connection refused: Unable to reach Zitadel at #{api_url}",
      }
    rescue Errno::EHOSTUNREACH
      {
        success: false,
        message: "Host unreachable: Check API URL is correct (#{api_url})",
      }
    rescue Timeout::Error
      {
        success: false,
        message: 'Connection timeout: Zitadel is not responding',
      }
    rescue StandardError => e
      {
        success: false,
        message: "Connection error: #{e.message}",
      }
    end

    # Generate OIDC RP-Initiated Logout URL for Zitadel.
    #
    # Creates a logout URL that will:
    # 1. Log the user out of Zitadel
    # 2. Redirect to the specified post_logout_redirect_uri
    #
    # Note: For best results, Zitadel requires an id_token_hint parameter, but since we don't
    # have access to the ID token in the Rails backend (only oauth2-proxy has it), we rely on
    # Zitadel's cookie-based session detection. Make sure post_logout_redirect_uri is allowed
    # in the Zitadel application's "Post Logout URIs" configuration.
    #
    # @param post_logout_redirect_uri [String] Where to redirect after logout
    # @param client_id [String, nil] Optional client_id to use (defaults to ZITADEL_IDP_WAREHOUSE_CLIENT_ID env var)
    # @return [String, nil] Logout URL or nil if api_url is not configured
    # @see https://zitadel.com/docs/apis/openidoauth/endpoints#end_session_endpoint
    def logout_url(post_logout_redirect_uri:, client_id: nil)
      return post_logout_redirect_uri unless api_url.present?

      # Include client_id for Zitadel to validate the post_logout_redirect_uri
      # Use provided client_id or fall back to environment variable
      client_id ||= ENV['ZITADEL_IDP_WAREHOUSE_CLIENT_ID']
      params = {
        post_logout_redirect_uri: post_logout_redirect_uri,
      }
      params[:client_id] = client_id if client_id.present?

      "#{api_url}/oidc/v1/end_session?#{params.to_query}"
    end

    # Build user data structure for bulk import (includes password hash and 2FA).
    #
    # @param user [User] User object from Rails app
    # @return [Hash] User data in Zitadel bulk import format
    def build_import_user_data(user)
      {
        userId: user.id.to_s,
        user: {
          userName: user.email,
          profile: {
            firstName: user.first_name,
            lastName: user.last_name,
            displayName: "#{user.first_name} #{user.last_name}",
            preferredLanguage: 'en',
          },
          email: {
            email: user.email,
            isEmailVerified: user.confirmed_at.present?,
          },
          hashedPassword: build_password_data(user),
          otpCode: extract_otp_secret(user),
          phone: build_phone_data(user),
        }.compact,
      }
    end

    # Bulk import multiple users to Zitadel (processes in single request).
    #
    # @param users [Array<User>] Array of User objects to import
    # @param timeout [String] Request timeout (default: '10m')
    # @return [Hash] Result with :success (Boolean), :imported_count (Integer), and optional :error (String)
    def bulk_import_users(users, timeout: '10m')
      human_users = users.map { |user| build_import_user_data(user) }

      import_data = {
        timeout: timeout,
        data_orgs: {
          orgs: [
            {
              orgId: org_id,
              humanUsers: human_users,
            },
          ],
        },
      }

      response = make_request(:post, '/admin/v1/import', body: import_data)

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
          error_message = error_data['message'] || error_data['error'] || response.body
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

    # Import users from JSON file (backwards compatibility with export format).
    #
    # @param file_path [String] Path to JSON file with bulk import data
    # @return [Hash] Result with :success (Boolean) and :response (Hash)
    # @raise [Idp::ServiceError] if file not found or import fails
    def import_from_file(file_path)
      raise Idp::ServiceError, "File not found: #{file_path}" unless File.exist?(file_path)

      import_data = JSON.parse(File.read(file_path))

      response = make_request(:post, '/admin/v1/import', body: import_data)

      case response.code.to_i
      when 200..299
        {
          success: true,
          response: JSON.parse(response.body),
        }
      else
        begin
          error_data = JSON.parse(response.body)
          error_message = error_data['message'] || error_data['error'] || response.body
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

    # Export users to bulk import format (without making API call).
    #
    # @param users [Array<User>] Array of User objects to export
    # @return [Hash] Zitadel bulk import JSON structure
    def export_users_to_import_format(users)
      human_users = users.map { |user| build_import_user_data(user) }

      {
        timeout: '10m',
        data_orgs: {
          orgs: [
            {
              orgId: org_id,
              humanUsers: human_users,
            },
          ],
        },
      }
    end

    private

    def api_url
      config[:api_url]
    end

    def token
      config[:service_token]
    end

    def org_id
      config[:org_id]
    end

    def project_id
      config[:project_id]
    end

    # Make HTTP request to Zitadel API.
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
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'
      request['x-zitadel-orgid'] = org_id if org_id.present?
      request.body = body.to_json if body

      http.request(request)
    end

    # Grant user access to the configured project.
    #
    # @param user_id [String] Zitadel user ID
    # @return [Boolean] true if access granted successfully
    # @raise [Idp::ServiceError] if grant fails
    def grant_project_access(user_id)
      return false unless project_id.present?

      # Grant user membership in the project
      # Note: Zitadel API structure may vary - this is a placeholder implementation
      # The actual endpoint might be something like:
      # POST /management/v1/projects/{project_id}/members
      # or
      # POST /management/v1/users/{user_id}/grants
      #
      # For now, we'll log a warning if project_id is set but we can't grant access
      Rails.logger.warn "Project ID configured but project access granting not yet implemented. User ID: #{user_id}, Project ID: #{project_id}"
      true
    end

    # Build password data hash for bulk import (bcrypt hash).
    #
    # @param user [User] User object from Rails app
    # @return [Hash, nil] Password data with algorithm and value, or nil if no password
    def build_password_data(user)
      return nil unless user.encrypted_password.present?

      {
        value: user.encrypted_password,
        algorithm: 'bcrypt',
      }
    end

    # Extract OTP secret from user (decrypts if present, handles errors gracefully).
    #
    # @param user [User] User object from Rails app
    # @return [String, nil] OTP secret or nil if not present or decryption fails
    def extract_otp_secret(user)
      return nil unless user.encrypted_otp_secret.present?

      begin
        user.otp_secret
      rescue StandardError => e
        Rails.logger.warn "Failed to decrypt OTP secret for #{user.email}: #{e.message}"
        nil
      end
    end

    # Build phone data hash for bulk import.
    #
    # @param user [User] User object from Rails app
    # @return [Hash, nil] Phone data with phone number, or nil if no phone
    def build_phone_data(user)
      return nil unless user.phone.present?

      {
        phone: user.phone,
        isPhoneVerified: false,
      }
    end

    protected

    def default_config
      {
        api_url: ENV['ZITADEL_API_URL'],
        service_token: ENV['ZITADEL_SERVICE_USER_TOKEN'],
        org_id: ENV['ZITADEL_ORG_ID'],
        project_id: ENV['ZITADEL_PROJECT_ID'],
      }
    end
  end
end
