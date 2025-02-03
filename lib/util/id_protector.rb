###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class IdProtector
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new env
    original_path = env['PATH_INFO']
    Rails.application.routes.router.recognize(request) do |route, params|
      decoded_key = false
      params.each do |key, value|
        next unless key == :id || key.to_s.ends_with?('_id')

        begin
          params[key] = ProtectedId::Encoder.decode(value)
        rescue OpenSSL::Cipher::CipherError => e
          # Suppress Cipher Errors so the response is handled by the controller as an unfound id.
          # Still capture the error in Sentry.
          Sentry.capture_exception(e)
        end
        decoded_key = true if value != params[key]
      end
      if decoded_key
        env['PATH_INFO'] = route.format(params)
      else
        # To be safe, reset the path
        env['PATH_INFO'] = original_path
      end
    end
    @app.call(env)
  end
end

require 'rack/attack'
class IdProtectorRailtie < ::Rails::Railtie
  initializer 'id-protector.middleware' do |app|
    # put id protector behind rack attack
    app.middleware.insert_after(Rack::Attack, IdProtector)
  end
end
