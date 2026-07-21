###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Admin-initiated account provisioning for the JWT arm. Given a chosen connector and identity
  # fields, provision (or link to an existing) account in the remote IdP, then persist the local
  # User and its durable connector link. This is the identity half only — roles/ACLs are assigned
  # afterward on the edit form.
  #
  # Mirrors the linkage that UserProvisioner establishes on JIT login (connector_id +
  # connector_user_id row, last_connector_id), but driven by an admin form and an explicit
  # connector rather than an inbound JWT.
  class AdminUserCreator
    def self.call(...)
      new(...).call
    end

    private_class_method :new

    def initialize(connector_id:, email:, first_name:, last_name:, user_class: User)
      @connector_id = connector_id
      @email = email
      @first_name = first_name
      @last_name = last_name
      @user_class = user_class
    end

    # @return [User] the persisted, IdP-linked user
    # @raise [ActiveRecord::RecordInvalid] the local user is invalid (e.g. email already in use locally)
    # @raise [Idp::ServiceError] the connector can't create users, or the remote create/lookup failed
    def call
      service = Idp::ServiceFactory.for_connector(@connector_id)
      raise Idp::ServiceError.new("#{service.idp_name} does not support creating users", idp_name: service.idp_name, operation: :create_user) unless service.supports_user_creation?

      # Claim the email locally first, via the users table's unique index, before making any
      # (irreversible) remote IdP call. That keeps a race between concurrent admin submissions
      # local and fast to resolve — the loser fails right here with a normal validation error —
      # instead of both racing to provision remote accounts and risking an orphaned IdP account
      # if the loser's local save fails only after it already created something remotely.
      user = build_user
      user.save!

      begin
        connector_user_id = resolve_connector_user_id(service)
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
        agency_id: 0,
      )
    end

    # Link an existing remote account when the email already exists in the IdP; otherwise create one.
    def resolve_connector_user_id(service)
      existing = service.find_user_by_email(email: @email)
      return existing['id'] if existing && existing['id'].present?

      service.create_user(email: @email, first_name: @first_name, last_name: @last_name).fetch(:connector_user_id)
    end
  end
end
