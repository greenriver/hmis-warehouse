###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class MaintenanceController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @maintenance = true

    render 'index', layout: 'maintenance'
  end
end
