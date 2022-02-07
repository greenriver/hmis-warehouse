###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class DoubleEnrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_limited, only: [:index]

    def index
      @date = (params[:date] || default_date).to_date
      @counts = GrdaWarehouse::ServiceHistoryService.residential.
        joins(service_history_enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        where(date: @date).group(:project_type, :client_id).
        having(nf('COUNT', [shs_t[:date]]).gt(1)).
        pluck(:client_id, :project_type, nf('STRING_AGG', [p_t[:ProjectName], ', ']).to_sql, nf('COUNT', [shs_t[:date]]).to_sql).group_by(&:first)
      @clients = client_source.where(id: @counts.keys).index_by(&:id)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def default_date
      Date.new(Date.current.year, 1, 1)
    end
  end
end
