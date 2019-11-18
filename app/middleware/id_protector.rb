###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###
class IdProtector
  def initialize(app)
    @app = app
  end

  def call(env)
    Rails.logger.error("PROTECTOR: PATH_INFO #{env['PATH_INFO']}")
    request = ActionDispatch::Request.new env
    Rails.application.routes.router.recognize(request) do | route, params |
      Rails.logger.error("PROTECTOR: PARAMS #{params}")
      params.each do |key, value|
        if key == :id || key.to_s.ends_with?('_id')
          params[key] = ProtectedId::Encoder.decode(value)
        end
      end
      env['PATH_INFO'] = route.format(params)
      Rails.logger.error("PROTECTOR: FORMAT PATH_INFO #{env['PATH_INFO']}")
    end
    @app.call(env)
  end
end
