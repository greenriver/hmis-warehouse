###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisApi::BaseController < ApplicationController
  respond_to :json
  before_action :set_csrf_cookie

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  def authenticate_user!
    authenticate_hmis_api_user!
  end
end
