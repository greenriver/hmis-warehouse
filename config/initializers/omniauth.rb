
###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: Devise's Omniauthable module does not support multiple models. It's necessary
# write our own glue.
# Reference:
# https://stackoverflow.com/a/13591797
# https://github.com/heartcombo/devise/wiki/OmniAuth-with-multiple-models

if ENV['OKTA_DOMAIN'].present?
  require 'omni_auth/strategies/custom_okta'

  domain = ENV.fetch('OKTA_DOMAIN')
  auth_server = ENV.fetch('OKTA_AUTH_SERVER') { 'default' }

  connection_build_callback = if Rails.env.development?
    puts 'OKTA: WARNING: request logging enabled'

    ->(builder) do
      builder.request :url_encoded
      builder.response :logger, Rails.logger, { headers: true, bodies: true, log_level: :debug }
      builder.adapter Faraday.default_adapter
    end
  end

  # options for ::OAuth2::Client
  client_options = {
    site: "https://#{domain}",
    authorize_url: "https://#{domain}/oauth2/#{auth_server}/v1/authorize",
    token_url: "https://#{domain}/oauth2/#{auth_server}/v1/token",
    user_info_url: "https://#{domain}/oauth2/#{auth_server}/v1/userinfo",
    connection_build: connection_build_callback,
  }

  # warehouse okta app
  if ENV['OKTA_CLIENT_ID']
    Rails.application.middleware.use OmniAuth::Builder do
      provider(
        OmniAuth::Strategies::CustomOkta,
        ENV.fetch('OKTA_CLIENT_ID'), ENV.fetch('OKTA_CLIENT_SECRET'),
        scope: 'openid profile email phone',
        fields: ['profile', 'email', 'phone'],
        name: 'wh_okta',
        path_prefix: "/users/auth",
        request_path: "/users/auth/okta",
        callback_path: "/users/auth/okta/callback",
        client_options: client_options,
      )
    end
  end

  # hmis okta app
  if ENV['HMIS_OKTA_CLIENT_ID']
    Rails.application.middleware.use OmniAuth::Builder do
      provider(
        OmniAuth::Strategies::CustomOkta,
        ENV.fetch('HMIS_OKTA_CLIENT_ID'), ENV.fetch('HMIS_OKTA_CLIENT_SECRET'),
        scope: 'openid profile email phone',
        fields: ['profile', 'email', 'phone'],
        name: 'hmis_okta',
        path_prefix: "/hmis/users/auth",
        request_path: "/hmis/users/auth/okta",
        callback_path: "/hmis/users/auth/okta/callback",
        full_host: "https://#{ENV.fetch('HMIS_HOSTNAME')}",
        client_options: client_options,
      )
    end
  end

  # configure failure
  class CustomFailureEndpoint < OmniAuth::FailureEndpoint
    def failure
      message_key = Rack::Utils.escape(env['omniauth.error.type'])
      origin = Rack::Utils.escape(env['omniauth.origin'])
      Rails.logger.info("omniauth failed: #{env['HTTP_REFERER']} #{[message_key, origin].inspect}")
      new_path = "/?sso_failed=1"
      Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
    end
  end
  OmniAuth.config.on_failure = Proc.new { |env| CustomFailureEndpoint.new(env).failure }

end
