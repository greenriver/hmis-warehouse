###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::SessionKeepalivesController < Hmis::BaseController
  def create
    render json: { success: true }
  end
end
