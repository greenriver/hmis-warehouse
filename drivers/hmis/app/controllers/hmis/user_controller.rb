###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserController < Hmis::BaseController
  skip_before_action :verify_authenticity_token, only: [:index]
  skip_before_action :authenticate_user!, only: [:index]

  # Endpoint to retrieve the currently logged-in user.
  #
  # This is called by the frontend on initial page load, to determine whether
  # there is a currently active session.
  #
  # If there is no active session, warden will return a 401.
  # We set a CSRF cookie *prior* to authentication, because the frontend
  # needs a valid CSRF token to hit POST /hmis/login.
  def index
    set_csrf_cookie
    authenticate_hmis_user!
    render json: {
      name: current_hmis_user.name,
      email: current_hmis_user.email,
    }
  end
end
