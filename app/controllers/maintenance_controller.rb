###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MaintenanceController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @maintenance = true

    render 'index', layout: 'maintenance'
  end
end
