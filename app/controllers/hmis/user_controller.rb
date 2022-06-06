###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class UserController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    respond_to :json

    def index
      # Set CSRF cookie even if no user is logged in, so that the client can send it with the login request
      set_csrf_cookie
      return render status: 406, json: { success: 'false', message: 'No user logged in' } unless current_hmis_user.present?

      authenticate_hmis_user!
      render json: {
        name: current_hmis_user.name,
        email: current_hmis_user.email,
        id: current_hmis_user.id,
      }
    end
  end
end
