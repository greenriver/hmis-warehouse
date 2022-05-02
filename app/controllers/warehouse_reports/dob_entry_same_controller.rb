###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class DOBEntrySameController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    def index
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      @clients = client_source.distinct.
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(source_enrollments: :project).
        where(client_source.arel_table[:DOB].eq et[:EntryDate]). # 'Client.DOB = EntryDate')
        where.not(DOB: nil).
        order(DOB: :asc)

      @pagy, @clients = pagy(@clients)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def enrollment_source
      GrdaWarehouse::Hud::Enrollment
    end

    private def data_source_source
      GrdaWarehouse::DataSource
    end
  end
end
