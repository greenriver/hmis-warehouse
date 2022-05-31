###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Api::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user
  before_action :check_request_format, only: [:create]
  respond_to :json

  def create
    resource = warden.authenticate!(auth_options)
    return render status: 401 if resource.blank?

    sign_in(resource_name, resource)
    render json: { success: true, jwt: current_token }
  end

  def check_request_format
    return if request.format == :json

    sign_out
    render status: 406, json: { success: 'false', message: 'JSON requests only.' }
  end

  private def current_token
    request.env['warden-jwt_auth.token']
  end
end
