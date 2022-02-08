###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ReallyOldEnrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]

    def index
      @date = (params[:date] || '1980-01-01').to_date
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      @clients = client_source.
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(:source_enrollments).
        where(et[:EntryDate].lt(@date)).
        order(:LastName, :FirstName).
        page(params[:page]).per(25)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
