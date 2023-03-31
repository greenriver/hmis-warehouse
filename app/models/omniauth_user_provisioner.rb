###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Find or create a user from omniauth info.
# If the user is new they will be assigned to a "Unknown" Agency and considered #confirmed_at Time.current.
# If the user already exists their name etc may be updated to reflect info from the provider.
# If the user already exist and #provider_changed? an ::ApplicationMailer#provider_linked
#    email letting them know will be scheduled.
class OmniauthUserProvisioner
  # @param auth [Hash] https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  # @param user_scope [User]
  def perform(auth:, user_scope:)
    log "find or provision user from #{auth['info']}"

    user = nil
    new_authorization_created = false
    new_user_created = false

    OauthIdentity.transaction do
      attrs = { provider: auth.provider, uid: auth.uid }
      # create an orphan authorzation to lock before creating a user
      now = Time.now
      OauthIdentity.upsert(attrs.merge(created_at: now, updated_at: now), unique_by: attrs.keys)
      OauthIdentity.find_by(attrs).lock!

      # load auth record after lock is aquired
      identity = OauthIdentity.find_by(attrs)

      # load or create a user record
      if identity.user_id.nil?
        new_authorization_created = true
        user = user_scope.find_or_build_for_oauth(email: auth['info']['email'])
        new_user_created = user.new_record?
      else
        user = user_scope.find(identity.user_id)
      end

      # treat oauth hash as authoritative for user info
      user.assign_attributes(
        email: auth['info']['email'],
        phone: auth.extra.raw_info[:phone_number],
        first_name: auth['info']['first_name'],
        last_name: auth['info']['last_name'],
      )

      user.skip_confirmation! unless user.confirmed?
      user.skip_reconfirmation!
      user.save!(validate: false)
      identity.raw_info = auth['extra'].merge(auth['credentials'])
      identity.user_id = user.id
      identity.save!
    end

    # Notify existing users the first time this provider is used to sign into their account
    if new_authorization_created && !new_user_created
      log "linking to pre-existing user. provider:#{auth.provider} uid:#{auth.uid} existing_user_id:#{user.id}"
      ::ApplicationMailer.with(user: user).provider_linked.deliver_later
    end

    # send notifications if this is a completely new user, or if the user was just connected to omniauth
    NotifyUser.new_account_created(user.reload).deliver_later if new_user_created
    user
  end

  protected

  def log(msg)
    method_name = caller_locations(1, 1)[0].label
    Rails.logger.debug "#{self.class.name}##{method_name} #{msg}"
  end

end
