###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DataSourceReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_limited, only: [:index]

    def index
      @data_sources = data_source_scope.order(name: :asc)
      @pagy, @data_sources = pagy(@data_sources)
      @client_counts = @data_sources.map { |ds| [ds.id, ds.client_count] }.to_h
      @project_counts = @data_sources.map { |ds| [ds.id, ds.project_count] }.to_h
    end

    private def data_source_source
      GrdaWarehouse::DataSource.viewable_by current_user
    end

    private def data_source_scope
      data_source_source.source
    end
  end
end
