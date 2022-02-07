###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class DvVictimServiceController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_limited, only: [:index]

    def index
      @project_types = params.dig(:filter, :project_types) || [2, 3, 13] # TH, PSH, RRH
      @start_date = params.dig(:filter, :start) || Date.current - 30.days
      @end_date = params.dig(:filter, :end) || Date.current
      project_ids = params.dig(:filter, :project_ids) || []

      @project_ids = project_ids.reject(&:blank?)
      @clients = clients.page(params[:page].to_i)
    end

    def filtered_project_list
      options = {}
      GrdaWarehouse::Hud::Project.viewable_by(current_user).
        merge(GrdaWarehouse::Hud::Project.with_project_type(@project_types)).
        joins(:organization).
        order(o_t[:OrganizationName].asc, ProjectName: :asc).
        pluck(o_t[:OrganizationName].as('org_name').to_sql, :ProjectName, GrdaWarehouse::Hud::Project.project_type_column, :id).each do |org, project_name, project_type, id|
        options[org] ||= []
        options[org] << ["#{project_name} (#{HUD.project_type_brief(project_type)})", id]
      end
      options
    end
    helper_method :filtered_project_list

    def clients
      scope = client_scope.
        joins(enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.with_project_type(@project_types))

      unless @project_ids.empty?
        scope = client_scope.
          joins(enrollments: :project).
          where(p_t[:id].in(@project_ids))
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
