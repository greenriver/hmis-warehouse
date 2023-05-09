###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module OmniauthSupport
  extend ActiveSupport::Concern

  module ClassMethods
    def find_for_database_authentication(*args)
      user = super

      # users who are using omniauth cannot log in
      # via a database password
      return nil if user&.external_idp?

      user
    end

    # @param email [String]
    def find_or_build_for_oauth(email:)
      if email.present?
        found = find_for_authentication(email: email)
        return found if found
      end
      default_agency = Agency.where(name: 'Unknown').first_or_create!
      new(password: Devise.friendly_token, agency: default_agency)
    end
  end

  # Does this user use an external identity provider. #provider says which one.
  # All other methods should return safe values if this is false.
  def external_idp?
    ENV['OKTA_DOMAIN'].present? && OauthIdentity.for_user(self).any?
  end

  # Remove the IDP present, reseting the password and
  # reactivating by default.
  #
  # @returns true if the external_idp? was previously true
  def unlink_idp(reset_password: true, reactivate: true)
    return false unless external_idp? # nothing to do

    raise 'user must be saved first' if new_record?

    transaction do
      oauth_identities.each(&:destroy!)

      if reactivate
        self.last_activity_at = Time.current
        self.expired_at = nil
        self.active = true
      end

      self.password = Devise.friendly_token if reset_password

      save!(validate: false)
    end

    send_reset_password_instructions if reset_password

    true
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
