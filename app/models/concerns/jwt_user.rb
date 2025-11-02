###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

module JwtUser
  extend ActiveSupport::Concern

  included do
    # Retrieves a user from JWT authentication. If the user is found and discarded,
    # it un-discards the user. If no user is found and auto user creation is allowed,
    # it creates a new user from the JWT.
    #
    # @param jwt [Jwt] the JWT object containing user information
    # @return [User, nil] the found or created user
    def self.from_jwt!(jwt, request)
      user = locate_user_by_authentication_source(jwt, request) || locate_user_by_email(jwt, request)

      user = create_user_from_jwt!(jwt, request) if ALLOW_AUTO_USER_CREATION && user.blank?

      user&.allowed_to_sign_in? ? user : nil
    rescue StandardError => e
      Sentry.capture_exception(e)

      nil
    end

    # Locates a user by their authentication source using the provided JWT.
    #
    # @param jwt [Jwt] the JWT object containing user information
    # @return [User, nil] the user associated with the authentication source
    def self.locate_user_by_authentication_source(jwt, request)
      source = UserAuthenticationSource.find_by(connector_id: jwt.connector_id, connector_user_id: jwt.connector_user_id)
      return unless source&.persisted? && source.enabled?

      source.undiscard! if source.discarded?
      update_user_from_jwt!(source.user, jwt, request)
    end

    # Locates a user by their email from the JWT.
    # If a user is found, an authentication source is added for the JWT
    #
    # @param jwt [Jwt] the JWT object containing user information
    # @return [User, nil] the user found by email
    def self.locate_user_by_email(jwt, request)
      user = where('email ILIKE ?', jwt.payload_email).first
      return unless user.present?

      user.user_authentication_sources.create!(
        user: user,
        connector_id: jwt.connector_id,
        connector_user_id: jwt.connector_user_id,
      )
      update_user_from_jwt!(user, jwt, request)
    end

    # Creates a new user from the provided JWT.
    #
    # @param jwt [Jwt] the JWT object containing user information
    # @return [User] the newly created user
    def self.create_user_from_jwt!(jwt, request)
      user = update_user_from_jwt!(User.new, jwt, request)
      user.user_authentication_sources.create!(
        user: user,
        connector_id: jwt.connector_id,
        connector_user_id: jwt.connector_user_id,
      )
      user
    end

    # Updates the user attributes based on the information from the JWT.
    #
    # @param user [User] the user to be updated
    # @param jwt [Jwt] the JWT object containing user information
    # @return [User] the updated user
    def self.update_user_from_jwt!(user, jwt, request)
      user.update!(
        first_name: jwt.first_name,
        last_name: jwt.last_name,
        email: jwt.payload_email,
        last_connector_id: jwt.connector_id,
        last_login_at: Time.at(jwt.last_login_at).in_time_zone,
        last_login_ip: request.remote_ip,
        last_activity_at: Time.now,
      )

      user
    end
  end
end
