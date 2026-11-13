###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module DataSourceReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_limited, only: [:index]

    def index
      @data_sources = data_source_scope.order(name: :asc)
      @pagy, @data_sources = pagy(@data_sources)
      data_source_ids = @data_sources.map(&:id)
      @client_counts = GrdaWarehouse::DataSource.client_counts_by_id(data_source_ids)
      @project_counts = GrdaWarehouse::DataSource.project_counts_by_id(data_source_ids)
      @unprocessed_enrollment_counts = GrdaWarehouse::DataSource.unprocessed_enrollment_counts_by_id(data_source_ids)
      @last_import_completed_ats = GrdaWarehouse::DataSource.last_import_completed_ats_by_id(data_source_ids)
      @stalled_dates = GrdaWarehouse::DataSource.stalled_dates_by_id(data_source_ids)
    end

    private def data_source_source
      GrdaWarehouse::DataSource.viewable_by current_user
    end

    private def data_source_scope
      data_source_source.source
    end
  end
end
