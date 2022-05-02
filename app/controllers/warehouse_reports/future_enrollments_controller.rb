###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class FutureEnrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    def index
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      @clients = client_source.
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(:source_enrollments).
        where(et[:EntryDate].gt(Date.current)).
        order(:LastName, :FirstName)

      @pagy, @clients = pagy(@clients)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
