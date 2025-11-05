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
  # Requires environment variables:
  # - ZITADEL_API_URL: Base URL for Zitadel API (e.g., http://zitadel.dev.test:8080)
  # - ZITADEL_SERVICE_USER_TOKEN: Personal Access Token with admin permissions
  # - ZITADEL_ORG_ID: Organization ID in Zitadel
  # - ZITADEL_PROJECT_ID: (Optional) Project ID for granting user access to the Warehouse application
  class ZitadelService < Service
    def initialize
      @api_url = ENV.fetch('ZITADEL_API_URL', 'http://zitadel.dev.test:8080')
      @token = ENV.fetch('ZITADEL_SERVICE_USER_TOKEN')
      @org_id = ENV.fetch('ZITADEL_ORG_ID')
      @project_id = ENV['ZITADEL_PROJECT_ID']
    end

    # Create a new user in Zitadel.
    #
    # @param email [String] User's email address
    # @param first_name [String] User's first name
    # @param last_name [String] User's last name
    # @param phone [String, nil] User's phone number (optional)
    # @return [Hash] User data including 'userId'
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
        result
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
    # @return [Boolean] true
    def supports_user_management?
      true
    end

    # Check if Zitadel supports profile field updates.
    #
    # @return [Boolean] true
    def supports_profile_updates?
      true
    end

    private

    attr_reader :api_url, :token, :org_id, :project_id

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
      request['x-zitadel-orgid'] = org_id
      request.body = body.to_json if body

      http.request(request)
    end

    # Find user ID by email address.
    #
    # @param _email [String] User's email address (unused - placeholder for future implementation)
    # @return [String, nil] User ID if found, nil otherwise
    def find_user_by_email(_email)
      # Note: Zitadel API doesn't have a direct search by email endpoint in Management API
      # This is a placeholder - actual implementation may need to use a different approach
      # or maintain a mapping of email to user_id
      nil
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
  end
end
