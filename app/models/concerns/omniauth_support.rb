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

    def from_omniauth(auth)
      logger.debug do
        "User#from_omniauth #{auth['info']}"
      end

      user = find_by(
        provider: auth['provider'],
        uid: auth['uid'],
      ) || find_by(
        email: auth['info']['email'],
      ) || new(
        password: Devise.friendly_token,
        confirmed_at: Time.current, # we are assuming its the providers job, not ours.
        agency: Agency.where(name: 'Unknown').first_or_create!,
      )

      # update this info from the provider whenever we can
      user.assign_attributes(
        provider: auth['provider'],
        uid: auth['uid'],
        email: auth['info']['email'],
        phone: auth.extra.raw_info[:phone_number],
        first_name: auth['info']['first_name'],
        last_name: auth['info']['last_name'],
        provider_raw_info: auth.extra.raw_info,
      )

      # Notify existing users the first time OKTA is used
      # to sign into their account
      if !user.new_record? && user.provider_changed?
        logger.info { "User#from_omniauth linking to pre-existing user. provider:#{user.provider} uid:#{user.uid} existing_user_id:#{user.id}" }
        ::ApplicationMailer.with(user: user).provider_linked.deliver_later
      end
      user.save(validate: false)
      user
    end
  end

  def external_idp?
    provider.present?
  end

  def confirm_password_for_admin_actions?
    !external_idp?
  end

  def email_change_enabled?
    !external_idp?
  end

  def password_change_enabled?
    !external_idp?
  end

  def send_reset_password_instructions
    return false if external_idp?

    super
  end

  def password_expiration_enabled?
    return false if external_idp?

    super
  end

  def pwned?
    return false if external_idp?

    super
  end
end
