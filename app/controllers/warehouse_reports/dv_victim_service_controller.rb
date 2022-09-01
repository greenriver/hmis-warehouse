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
    before_action :set_filter, only: [:index]

    def index
      @pagy, @clients = pagy(clients)
    end

    def clients
      scope = client_scope.
        joins(enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.with_project_type(@filter.project_type_ids))

      unless @filter.project_ids.empty?
        scope = client_scope.
          joins(enrollments: :project).
          where(p_t[:id].in(@filter.project_ids))
      end

      scope.order(:FirstName, :LastName)
    end

    def client_scope
      GrdaWarehouse::Hud::Client.
        joins(:health_and_dvs, enrollments: :project).
        where(hdv_t[:InformationDate].gteq(@filter.start).and(hdv_t[:InformationDate].lteq(@filter.end).and(hdv_t[:CurrentlyFleeing].eq(1)))).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        distinct
    end

    private def set_filter
      @filter = ::Filters::FilterBase.new(
        filter_params.merge(
          user_id: current_user.id,
          default_start: Date.current - 1.month,
          default_end: Date.current,
        ),
      )
      # Default project type ids [2, 3, 10, 13]
      @filter.project_type_codes = [:th, :psh, :rrh] unless filter_params[:project_type_codes].present?
    end

    private def filter_params
      return {} unless params[:filters]

      params.require(:filters).permit(::Filters::FilterBase.new(user_id: current_user.id).known_params)
    end
  end
end
