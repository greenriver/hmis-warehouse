class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cognito
    auth = request.env['omniauth.auth']
    user = User.where(provider: auth.provider, uid: auth.uid).first_or_create do |u|
      u.email = auth.info.email
      u.password = Devise.friendly_token[0, 20]
      u.first_name = auth.extra.raw_info.given_name || 'Anonymous'
      u.last_name = auth.extra.raw_info.family_name || 'User'
      u.phone = auth.extra.raw_info.phone_number
      u.skip_confirmation!
    end
    user.update_columns(
      provider_raw_info: auth.extra.raw_info.to_h.merge(auth.credentials.to_h),
    )

    if user.persisted?
      sign_in_and_redirect user, event: :authentication # this will throw if user is not activated
      set_flash_message(:notice, :success, kind: 'Cognito') if is_navigational_format?
    else
      raise user.errors.full_messages.inspect if Rails.env.development?

      session['devise.cognito_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to root_url, alert: user.errors.full_messages.inspect
    end
  end

  def failure
    redirect_to root_path
  end
end
