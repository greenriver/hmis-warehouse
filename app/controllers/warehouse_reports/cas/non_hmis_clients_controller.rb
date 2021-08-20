###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class NonHmisClientsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      @report = ::Cas::NonHmisClient.find_matches(report_source)
    end

    def match
      matches = match_params[:clients].
        reject { |k, v| k.blank? || v.blank? }.
        transform_keys(&:to_i).
        transform_values(&:to_i)

      report_source.import(
        matches.to_h.map { |k, v| { id: k, warehouse_client_id: v } },
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:warehouse_client_id],
        },
      )
      redirect_to url_for(action: :index)
    end

    private def match_params
      params.permit(clients: {})
    end

    private def report_source
      ::Cas::NonHmisClient.unassigned
    end
  end
end
