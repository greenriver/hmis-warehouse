###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module OmniauthSupport
  extend ActiveSupport::Concern

  included do
    devise :omniauthable, omniauth_providers: [:okta] if ENV['OKTA_DOMAIN'].present?
  end

  module ClassMethods
    def find_for_database_authentication(*args)
      user = super

      # users who are using omniauth cannot log in
      # via a database password
      return nil if user&.external_idp?

      user
    end

    # Find or create a from omniauth info.
    # If the user is new they will be assigned to a "Unknown" Agency and considered #confirmed_at Time.current.
    # If the user already exists their name etc may be updated to reflect info from the provider.
    # If the user already exist and #provider_changed? an ::ApplicationMailer#provider_linked
    #    email letting them know will be scheduled.
    def from_omniauth(auth)
      logger.debug do
        "User#from_omniauth #{auth['info']}"
      end

      user = find_by(
        provider: auth['provider'],
        uid: auth['uid'],
      ) || find_for_authentication(
        email: auth['info']['email'],
      ) || new(
        password: Devise.friendly_token,
        agency: Agency.where(name: 'Unknown').first_or_create!,
      )

      # Update this info from the provider whenever we can
      user.assign_attributes(
        provider: auth['provider'],
        uid: auth['uid'],
        email: auth['info']['email'],
        phone: auth.extra.raw_info[:phone_number],
        first_name: auth['info']['first_name'],
        last_name: auth['info']['last_name'],
        provider_raw_info: auth['extra'].merge(auth['credentials']),
      )

      newly_created = user.new_record? || user.provider_set_at.blank?

      # Notify existing users the first time OKTA is used
      # to sign into their account
      if !user.new_record? && user.provider_set_at.blank?
        logger.info { "User#from_omniauth linking to pre-existing user. provider:#{user.provider} uid:#{user.uid} existing_user_id:#{user.id}" }
        user.provider_set_at = Time.current
        ::ApplicationMailer.with(user: user).provider_linked.deliver_later
      end

      user.skip_confirmation! unless user.confirmed?
      user.skip_reconfirmation!
      user.save(validate: false)

      # send notifications if this is a completely new user, or if the user was just connected to omniauth
      NotifyUser.new_account_created(user.reload).deliver_later if newly_created

      user
    end
  end

  # Does this user use an external identity provider. #provider says which one.
  # All other methods should return safe values if this is false.
  def external_idp?
    provider.present? && ENV['OKTA_DOMAIN'].present?
  end

  # Remove the IDP present, reseting the password and
  # reactivating by default.
  #
  # @returns true if the external_idp? was previously true
  def unlink_idp(reset_password: true, reactivate: true)
    return false unless external_idp? # nothing to do

    raise 'user must be saved first' if new_record?

    assign_attributes(
      provider: nil,
      uid: nil,
      provider_set_at: nil,
    )

    if reactivate
      self.last_activity_at = Time.current
      self.expired_at = nil
      self.active = true
    end

    self.password = Devise.friendly_token if reset_password

    save(validate: false)

    send_reset_password_instructions if reset_password

    true
  end

  def idp_signout_url(post_logout_redirect_uri: nil, state: 'provider-was-okta')
    return post_logout_redirect_uri unless external_idp? && provider == 'okta'

    # https://developer.okta.com/docs/reference/api/oidc/#logout
    #
    issuer = provider_raw_info.dig('id_info', 'iss')
    id_token = provider_raw_info['id_token']

    return unless issuer.present? && id_token.present?

    "#{issuer}/v1/logout?" + {
      id_token_hint: id_token,
      post_logout_redirect_uri: post_logout_redirect_uri,
      state: state,
    }.compact.to_param
  end

  # Users who don't have a local password cannot be asked to confirm it
  def confirm_password_for_admin_actions?
    !external_idp?
  end

  # Users who use a external IDP probably dont want to change
  # their email here only.
  def email_change_enabled?
    !external_idp?
  end

  # Users who don't have a local password cannot be asked to change it
  def password_change_enabled?
    !external_idp?
  end

  def send_reset_password_instructions
    # doesn't make sense for users who cant use a local password
    return false if external_idp?

    super
  end

  def password_expiration_enabled?
    # doesn't make sense for users who cant use a local password
    return false if external_idp?

    super
  end

  def pwned?
    # doesn't make sense for users who cant use a local password
    return false if external_idp?

    super
  end
end
