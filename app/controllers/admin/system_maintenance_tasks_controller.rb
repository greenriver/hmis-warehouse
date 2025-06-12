# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# tests for proper deprecation handling
module Admin
  class SystemMaintenanceTasksController < ApplicationController
    helper ElapsedTimeHelper
    before_action :require_can_manage_config!

    def index
      @tasks = scope.all.order(:name)
    end

    protected

    def scope
      GrdaWarehouse::Tasks::SystemMaintenanceTask
    end
  end
end
