###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::SessionKeepalivesController < Hmis::BaseController
  def create
    render json: { success: true }
  end
end
