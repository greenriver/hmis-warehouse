###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class DvVictimServiceController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_limited, only: [:index]

    def index
      @start_date = params.dig(:filter, :start) || Date.current - 30.days
      @end_date = params.dig(:filter, :end) || Date.current
      project_ids = params.dig(:filter, :project_ids)|| []

      @project_ids = project_ids.reject{ |id| id.blank? }
      @clients = clients.page(params[:page].to_i)
    end

    def clients
      project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th, :ph).flatten
      if @project_ids.length > 0
        scope = client_scope.
          joins(enrollments: :project).
          where(p_t[:id].in(@project_ids))
      else
        scope = client_scope.
          joins(enrollments: :project).
          merge(GrdaWarehouse::Hud::Project.with_project_type(project_types))
      end
      scope.order(:FirstName, :LastName)
    end

    def client_scope
      GrdaWarehouse::Hud::Client.
        joins(:health_and_dvs, enrollments: :project).
        where(hdv_t[:InformationDate].gteq(@start_date).and(hdv_t[:InformationDate].lteq(@end_date).and(hdv_t[:CurrentlyFleeing].eq(1)))).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        distinct
    end
  end
end