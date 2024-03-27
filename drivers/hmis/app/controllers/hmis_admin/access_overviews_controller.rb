###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisAdmin
  class AccessOverviewsController < ApplicationController
    include AjaxModalRails::Controller
    include EnforceHmisEnabled

    before_action :require_hmis_admin_access!

    def index
      @modal_size = :xl
    end
  end
end
