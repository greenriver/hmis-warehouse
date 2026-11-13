###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
