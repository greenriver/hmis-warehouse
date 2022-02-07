###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        if key == :id || key.to_s.ends_with?('_id')
          params[key] = ProtectedId::Encoder.decode(value)
          decoded_key = true if value != params[key]
        end
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
