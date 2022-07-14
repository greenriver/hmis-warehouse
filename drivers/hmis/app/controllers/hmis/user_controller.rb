###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserController < HmisApi::BaseController
  skip_before_action :verify_authenticity_token, only: [:index]
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # Set CSRF cookie even if no user is logged in, so that the client can send it with the login request
    set_csrf_cookie
    authenticate_hmis_user!
    render json: {
      name: current_hmis_user.name,
      email: current_hmis_user.email,
    }
  end

  def logout
    sign_out(:hmis_user) # Sign out of the HMIS
    render json: { success: true }, status: 204
  end
end
