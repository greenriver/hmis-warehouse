###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class LongStandingClientsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      # using date instead of first_date_in_program below because it is indexed
      # and is identical on entry records
      @years = (params[:years] || 5).to_i
      @entries = service_history_source.
        select(:first_date_in_program, :last_date_in_program, :client_id, :project_name).
        where(she_t[:date].lteq(@years.years.ago)).
        where(last_date_in_program: nil).
        es

      @pagy, @entries = pagy(@entries)
      @clients = client_source.where(id: @entries.map(&:client_id)).preload(source_clients: :data_source).index_by(&:id)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    private def data_source_source
      GrdaWarehouse::DataSource.importable
    end
  end
end
