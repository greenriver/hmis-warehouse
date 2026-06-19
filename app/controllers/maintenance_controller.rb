###
# Copyright Green River Data Group, Inc.
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
