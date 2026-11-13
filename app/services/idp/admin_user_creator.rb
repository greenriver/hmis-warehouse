###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Admin-initiated JWT provisioning: creates the local user, and links/creates the remote IdP
  # account when the connector supports_user_creation?. Identity only; roles/ACLs come later.
  class AdminUserCreator
    def self.call(...)
      new(...).call
    end

    private_class_method :new

    # @param connector_id [String, nil] nil creates a local account only: no remote account is
    #   provisioned and no UserAuthenticationSource is written.
    def initialize(connector_id:, email:, first_name:, last_name:, agency_id: nil, user_class: User)
      @connector_id = connector_id
      # Normalize the same way Idp::JwtHelper#payload_email does.
      @email = email&.strip&.downcase
      @first_name = first_name
      @last_name = last_name
      @agency_id = agency_id
      @user_class = user_class
    end

    # @raise [ActiveRecord::RecordInvalid] the local user is invalid (e.g. email already in use)
    # @raise [Idp::ServiceError] the remote create/lookup failed on a management-API connector
    def call
      service = Idp::ServiceFactory.for_connector(@connector_id)

      # Claim the email locally (unique index) before any irreversible remote call, so concurrent
      # submissions race on the local save rather than on provisioning remote accounts.
      user = build_user
      user.save!

      # No management API: link happens by email on first JWT sign-in.
      return user unless service.supports_user_creation?

      begin
        connector_user_id = find_or_create_connector_user_id(service)
        @user_class.transaction do
          user.user_authentication_sources.create!(connector_id: @connector_id, connector_user_id: connector_user_id)
          user.update!(last_connector_id: @connector_id)
        end
      rescue Idp::ServiceError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        begin
          user.destroy!
        rescue StandardError => cleanup_error
          Sentry.capture_exception_with_info(
            cleanup_error,
            'AdminUserCreator: failed to roll back local user after provisioning failure',
            { user_id: user.id, connector_id: @connector_id },
          )
        end
        raise e
      end

      user
    end

    private

    def build_user
      @user_class.new(
        email: @email,
        first_name: @first_name,
        last_name: @last_name,
        active: true,
        agency_id: @agency_id,
      )
    end

    def find_or_create_connector_user_id(service)
      existing = service.find_user_by_email(email: @email)
      if existing
        # A match with no id is contradictory: the IdP claims this email exists but gives us nothing
        # to link on. Creating a new account would duplicate it (or 409), so fail loudly instead.
        if existing['id'].blank?
          raise Idp::ServiceError.new(
            "IdP returned a match with no id for #{@email}",
            idp_name: service.idp_name,
            operation: :find_user_by_email,
            transient: false,
          )
        end

        return existing['id']
      end

      service.create_user(email: @email, first_name: @first_name, last_name: @last_name).fetch(:connector_user_id)
    end
  end
end
