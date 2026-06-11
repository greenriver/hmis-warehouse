###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  class UserProvisioner
    def self.call(jwt_helper:, user_class:, allow_create:, learn:)
      new(jwt_helper: jwt_helper, user_class: user_class, allow_create: allow_create, learn: learn).call
    end

    private_class_method :new

    def call
      return nil unless validate_and_extract_claims

      user = find_existing_user
      if !user && @allow_create
        user = create_user
        Rails.logger.warn("JIT-provisioned user id=#{user.id} via connector #{@connector_id}")
      end
      return nil unless user

      # Learn the durable connector link for every resolved user (existing or
      # JIT-created), independent of whether JIT-creation was allowed.
      if @learn
        ensure_authentication_source(user)
        update_last_connector(user)
      end

      user
    end

    private

    def initialize(jwt_helper:, user_class:, allow_create:, learn:)
      @jwt_helper = jwt_helper
      @user_class = user_class
      @allow_create = allow_create
      @learn = learn
    end

    def validate_and_extract_claims
      return false unless @jwt_helper.token? && @jwt_helper.valid?

      @email = @jwt_helper.payload_email
      @connector_id = @jwt_helper.connector_id
      @connector_user_id = @jwt_helper.connector_user_id

      @email.present? && @connector_id.present? && @connector_user_id.present?
    end

    # The  attributes that identify one IdP link.
    def connector_identity
      { connector_id: @connector_id, connector_user_id: @connector_user_id }
    end

    def find_existing_user
      auth_source = UserAuthenticationSource.
        where(connector_identity).
        order(:id).
        first

      return auth_source.user if auth_source

      user = @user_class.find_by(email: @email)
      Rails.logger.info("JWT email-fallback lookup matched user id=#{user.id} via connector #{@connector_id}") if user
      user
    end

    def create_user
      # create!, not upsert: upsert skips the callbacks/validations a User needs
      # (create_access_group, paper_trail, presence checks). Rescue handles the
      # rare concurrent-provision race on the unique email.
      # password only satisfies Devise :secure_validatable; drop when devise is gone
      TodoOrDie('Remove devise password behavior', if: !defined?(Devise))
      password = SecureRandom.base64(32)
      @user_class.create!(
        email: @email,
        first_name: @jwt_helper.first_name || 'User',
        last_name: @jwt_helper.last_name || '',
        confirmed_at: Time.current,
        active: true,
        agency_id: 0,
        password: password,
        password_confirmation: password,
      )
    rescue ActiveRecord::RecordNotUnique
      @user_class.find_by!(email: @email)
    end

    def ensure_authentication_source(user)
      # Prefer a live row; otherwise restore the most recently deleted record so the
      # row's id/created_at/history survive. The unique index is partial
      # (WHERE deleted_at IS NULL), so a tombstone never blocks this.
      source = UserAuthenticationSource.where(connector_identity).first ||
        UserAuthenticationSource.only_deleted.where(connector_identity).order(updated_at: :desc).first ||
        UserAuthenticationSource.new(connector_identity)

      # Strictly shouldn't happen: connector_user_id is the IdP's stable per-user
      # id, so a pair maps to exactly one of our users.
      if source.persisted? && source.user_id != user.id
        Sentry.capture_message(
          'IdP: connector pair already linked to a different user',
          level: :error,
          extra: {
            connector_id: @connector_id,
            connector_user_id: @connector_user_id,
            existing_user_id: source.user_id,
            attempted_user_id: user.id,
          },
        )
        return
      end

      source.restore if source.deleted?
      source.user = user
      source.save!
    rescue ActiveRecord::RecordNotUnique
      # Lost a concurrent first-login race; a live row for this pair now exists.
      nil
    end

    def update_last_connector(user)
      # update!, not update_column, so paper_trail records the change.
      user.update!(last_connector_id: @connector_id) if user.last_connector_id != @connector_id
    end
  end
end
