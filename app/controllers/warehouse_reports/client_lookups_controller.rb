###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ClientLookupsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    def index
      @filter = ::Filters::FilterBase.new(user_id: current_user.id, enforce_one_year_range: false).update(report_params)
      respond_to do |format|
        format.html {}
        format.xlsx do
          @start_date = @filter.start
          @end_date = @filter.end
          @project_ids = @filter.effective_project_ids

          @rows = client_source.
            joins(:warehouse_client_source, enrollments: :project).
            merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@start_date .. @end_date)).
            merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)).
            distinct.
            order(wc_t[:destination_id].asc, LastName: :asc, FirstName: :asc).
            pluck(wc_t[:destination_id], :PersonalID, :FirstName, :LastName)
          render xlsx: 'report', filename: 'client_lookups.xlsx'
        end
      end
    end

    private def report_params
      return nil unless params[:report].present?

      params.require(:report).
        permit(
          :start_date,
          :end_date,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
        )
    end

    private def client_source
      GrdaWarehouse::Hud::Client.source
    end
  end

  private def project_source
    GrdaWarehouse::Hud::Project.viewable_by(current_user)
  end
end
