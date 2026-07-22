###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT (AUTH_METHOD=jwt) authentication behavior for User / Hmis::User.
#
module Idp::JwtUser
  extend ActiveSupport::Concern

  class_methods do
    def find_or_create_from_jwt(jwt_helper)
      allow_create = AppConfigProperty.find_by(key: 'idp/auto_create_user')&.value == 'true'
      Idp::UserProvisioner.call(jwt_helper: jwt_helper, user_class: self, allow_create: allow_create, learn: true)
    end

    def find_from_jwt(jwt_helper)
      Idp::UserProvisioner.call(jwt_helper: jwt_helper, user_class: self, allow_create: false, learn: false)
    end

    def setup_system_user
      user = find_by(email: 'noreply@greenriver.com')
      return user if user.present?

      user = only_deleted.find_by(email: 'noreply@greenriver.com')
      user&.restore
      return user if user.present?

      user = new(
        email: 'noreply@greenriver.com',
        first_name: 'System',
        last_name: 'User',
        agency_id: 0,
        active: true,
      )
      user.save!
      user
    end
  end

  included do
    # JWT: the IdP owns expiry/inactivity, so activity reduces to the `active` flag.
    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

    # JWT: there is no warehouse session concept that can be managed in the warehouse
    scope :has_recent_activity, -> { none }
  end

  def active?
    active
  end

  def inactive?
    !active?
  end

  def overall_status(_current_user)
    return ['Active'] if active?

    ['Account deactivated']
  end

  def stale_account?
    # JWT: current_sign_in_at is a Devise :trackable column, stale under JWT;
    false
  end

  def two_factor_enabled?
    false # JWT: 2FA is IdP-managed; the otp_secret accessor is absent
  end

  def invitation_status
    nil
  end
end
