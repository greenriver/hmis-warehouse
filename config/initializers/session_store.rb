# Rails.logger.debug "Running initializer in #{__FILE__}"

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_boston-hmis_session', httponly: true, secure: Rails.env.production?
