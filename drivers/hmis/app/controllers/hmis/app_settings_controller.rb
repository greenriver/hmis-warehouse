###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AppSettingsController < Hmis::BaseController
  skip_before_action :authenticate_user!
  prepend_before_action :skip_timeout

  def show
    render json: {
      oktaPath: ENV['OKTA_DOMAIN'].present? ? '/users/auth/okta' : nil,
    }
  end
end
