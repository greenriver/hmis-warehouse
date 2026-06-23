###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Devise (AUTH_METHOD=devise) authentication behavior for User / Hmis::User.
#
module DeviseUser
  extend ActiveSupport::Concern

  class_methods do
    def setup_system_user
      user = find_by(email: 'noreply@greenriver.com')
      return user if user.present?

      user = only_deleted.find_by(email: 'noreply@greenriver.com')
      user&.restore
      return user if user.present?

      invite!(email: 'noreply@greenriver.com', first_name: 'System', last_name: 'User', agency_id: 0) do |u|
        u.skip_invitation = true
      end
    end
  end

  included do
    # Include default devise modules. Others available are:
    devise :invitable,
           :recoverable,
           :rememberable,
           :trackable,
           # :validatable,
           :secure_validatable,
           :lockable,
           :timeoutable,
           :confirmable,
           :session_limitable,
           :pwned_password,
           :expirable,
           :password_expirable,
           :password_archivable,
           :two_factor_authenticatable,
           :two_factor_backupable,
           password_length: 10..128,
           otp_secret_encryption_key: ENV['ENCRYPTION_KEY'],
           otp_secret_length: 26, # 128 bits keys, per RFC 4226. See GHSA-qjxf-mc72-wjr2
           otp_number_of_backup_codes: 10

    scope :active, -> {
      where(
        arel_table[:active].eq(true).and(
          arel_table[:expired_at].eq(nil).
          or(arel_table[:expired_at].gt(Time.current)),
        ).and(
          arel_table[:last_activity_at].eq(nil).
          or(arel_table[:last_activity_at].gt(expire_after.ago)),
        ),
      )
    }

    scope :inactive, -> {
      where(
        arel_table[:active].eq(false).
        or(arel_table[:expired_at].lteq(Time.current)).
        or(arel_table[:last_activity_at].lteq(expire_after.ago)),
      )
    }

    # users that have currently active sessions (either in the warehouse or in HMIS)
    scope :has_recent_activity, -> {
      where(last_activity_at: timeout_in.ago..Time.current).
        where.not(unique_session_id: nil, hmis_unique_session_id: nil)
    }

    # These methods override behavior the `devise` macro injects, and they `super` back into it. They must
    # be defined here, inside `included do`, rather than as plain `DeviseUser` instance/class methods.
    #
    # The `devise` macro above runs while DeviseUser is being included into the host class, so it inserts
    # the Devise modules *above* DeviseUser in the ancestor chain. A plain `def` in the module body would
    # therefore be shadowed by Devise's own implementation (and `super` would skip our logic). Defining
    # them on the host class itself keeps them below the macro modules so the override wins and `super`
    # reaches Devise.

    def active_for_authentication?
      super && active
    end

    # Allow logins to be case insensitive at login time
    def self.find_for_authentication(conditions)
      conditions[:email].downcase!
      super(conditions)
    end

    # Enforce a known value is included in the devise salt
    # this allows us to invalidate sessions even though they are stored in redis
    def authenticatable_salt
      base_salt = super
      return base_salt if custom_session_invalidator.blank?

      # Poison the salt to force the user to re-login by changing custom_session_invalidator
      # Make sure the salt isn't changing length
      Digest::SHA256.base64digest("#{base_salt}#{custom_session_invalidator}")[0, base_salt.length]
    end

    # Prevent sending confirmation emails if the user has an open invitation
    def send_reset_password_instructions
      if invitation_token.present?
        errors.add :email, 'There is an open invitation for this account.'
        false
      else
        super
      end
    end

    # Prevent confirming accounts if the user has an open invitation
    def pending_any_confirmation
      if invitation_token.present?
        errors.add :email, 'There is an open invitation for this account.'
        false
      else
        super
      end
    end
  end

  def timeout_time(session)
    # FIXME: move to helper. This doesn't belong on the model
    Time.current + (Devise.timeout_in - (Time.now.utc - (session['last_request_at'].presence || 0)).to_i)
  end

  def stale_account?
    current_sign_in_at < self.class.stale_account_threshold
  end

  def future_expiration?
    expired_at.present? && expired_at > Time.current
  end

  def two_factor_enabled?
    otp_secret.present? && otp_required_for_login? && passed_2fa_confirmation?
  end

  def invitation_status
    if invitation_accepted_at.present? || invitation_sent_at.blank?
      :active
    elsif invitation_due_at > Time.now
      :pending_confirmation
    else
      :invitation_expired
    end
  end

  def two_factor_label
    label = Translation.translate('Open Path HMIS Warehouse')
    Rails.env.production? ? label : "#{label} [#{Rails.env}]"
  end

  def two_factor_issuer
    "#{two_factor_label} #{email}"
  end

  # clears all otp secrets
  def reset_two_factor_model_attrs
    self.encrypted_otp_secret = nil
    self.encrypted_otp_secret_iv = nil
    self.encrypted_otp_secret_salt = nil
    self.otp_backup_codes = nil
    self.otp_secret = nil
    self.confirmed_2fa = 0
    self.otp_required_for_login = false
  end

  # ensure we have a secret
  def set_initial_two_factor_secret!
    return if otp_secret.present?

    update(otp_secret: User.generate_otp_secret)
  end

  def confirmation_step
    (confirmed_2fa + 1).ordinalize
  end

  def passed_2fa_confirmation?
    confirmed_2fa.positive?
  end

  def disable_2fa!
    update(
      confirmed_2fa: 0,
      otp_required_for_login: false,
      otp_backup_codes: nil,
    )
  end

  def record_failure_and_lock_access_if_exceeded!
    # Due to a bug, failed PWs double increment failed attempts. To
    # compensate, we double the lockout threshold. To match the PW
    # behavior, double up on failures due to OTP
    # https://github.com/tinfoil/devise-two-factor/issues/28
    transaction do
      2.times do # intentional double increment
        increment_failed_attempts
      end
    end
    # outside of transaction since this method sends email
    return unless attempts_exceeded?

    lock_access! unless access_locked?
  end

  def force_logout!
    update_attribute(:custom_session_invalidator, SecureRandom.hex)
  end

  # Dependent on devise expire_password_after being set to a value other than false
  def force_password_reset!
    return false unless password_expiration_enabled?

    # Immediately logout the user
    self.custom_session_invalidator = SecureRandom.hex
    # Force a password change on next login
    need_change_password! # calls save internally

    # Return true to indicate success
    true
  end

  def skip_session_limitable?
    ENV.fetch('SKIP_SESSION_LIMITABLE', false) == 'true'
  end

  def inactive?
    return true unless active?

    expired?
  end

  # supports admin user management
  # @return [Array] an array of text that describes the status of the account
  def overall_status(current_user)
    return ['Active'] if active_for_authentication?
    return ['Pending invitation confirmation'] if invitation_status == :pending_confirmation

    text = []
    text << 'Invitation expired' if invitation_status == :invitation_expired
    if expired_at?
      text << "Account expired on #{expired_at}"
    elsif expired?
      text << "Account expired due to inactivity. Last activity on #{last_activity_at}"
    else
      text << deactivation_status(current_user)
    end
    text
  end

  private def deactivation_status(user)
    return unless inactive?

    # The PaperTrail versions association has a fixed order with newest last
    version = versions.where(event: 'deactivate').last

    return 'Account deactivated' unless version
    return "Account deactivated on #{version.created_at}" unless user.can_audit_users? || version.whodunnit.blank?

    name = nil
    name = User.find_by(id: version.whodunnit)&.name if version.whodunnit&.to_i&.to_s == version.whodunnit

    return "Account deactivated on #{version.created_at}" unless name

    "Account deactivated by #{name} on #{version.created_at}"
  end
end
