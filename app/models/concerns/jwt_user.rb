###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern providing JWT-based user lookup for User model.
#
# Provides methods to find or create users based on JWT token information.
# Handles linking users to authentication sources based on connector_id and connector_user_id.
module JwtUser
  extend ActiveSupport::Concern

  included do
    # Find or create a user based on JWT helper information.
    #
    # @param jwt_helper [JwtHelper] Instance of JwtHelper with validated token
    # @return [User, nil] User instance or nil if token is invalid
    # @raise [StandardError] if user creation fails
    def self.find_or_create_from_jwt(jwt_helper)
      return nil unless jwt_helper.token? && jwt_helper.validate!

      email = jwt_helper.payload_email
      connector_id = jwt_helper.connector_id
      connector_user_id = jwt_helper.connector_user_id

      return nil if email.blank? || connector_id.blank? || connector_user_id.blank?

      # Find user by email first
      user = find_by(email: email.downcase)

      # If user doesn't exist, create them
      user ||= create!(
        email: email.downcase,
        first_name: jwt_helper.first_name.presence || 'User',
        last_name: jwt_helper.last_name.presence || '',
        confirmed_at: Time.current, # Users coming from IDP are already confirmed
        active: true,
        agency_id: 0, # Unknown agency
      )

      # Find or create authentication source
      auth_source = user.user_authentication_sources.find_or_initialize_by(
        connector_id: connector_id,
        connector_user_id: connector_user_id,
      )

      if auth_source.new_record? || auth_source.deleted?
        auth_source.enabled = true
        auth_source.save!
        # Restore if it was soft-deleted
        auth_source.restore if auth_source.deleted?
      end

      # Update last_connector_id if this is a different connector
      user.update_column(:last_connector_id, connector_id) if user.last_connector_id != connector_id

      user
    end

    # Find user by JWT helper information.
    #
    # @param jwt_helper [JwtHelper] Instance of JwtHelper with validated token
    # @return [User, nil] User instance or nil if not found
    def self.find_from_jwt(jwt_helper)
      return nil unless jwt_helper.token? && jwt_helper.validate!

      email = jwt_helper.payload_email
      connector_id = jwt_helper.connector_id
      connector_user_id = jwt_helper.connector_user_id

      return nil if email.blank? || connector_id.blank? || connector_user_id.blank?

      # Try to find by authentication source first (most reliable)
      auth_source = UserAuthenticationSource.
        where(connector_id: connector_id, connector_user_id: connector_user_id).
        where(deleted_at: nil).
        first

      return auth_source.user if auth_source

      # Fallback to email lookup
      find_by(email: email.downcase)
    end
  end
end
