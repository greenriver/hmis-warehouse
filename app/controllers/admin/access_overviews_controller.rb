###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class AccessOverviewsController < ApplicationController
    include AjaxModalRails::Controller

    before_action :require_can_edit_roles!

    def index
      @modal_size = :xl
    end
  end
end
