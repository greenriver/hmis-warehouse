###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  # Ids and dates only, never PII; the client links enforce their own access, so report
  # assignment is the only gate.
  class ClientRetentionController < ApplicationController
    include WarehouseReportAuthorization

    EXPIRING_WITHIN_DAYS = 90

    before_action :set_global_years

    # Records Expiring Soon. The views paginate via render_paginated_list.
    def index
      @expiring = if @global_years.nil?
        []
      else
        # ponytail: live scan of every linked destination on an admin page; persist the
        # expiring set from the nightly run if this gets slow.
        GrdaWarehouse::InactiveClient.
          rollup_activity(destination_ids: nil, global_years: @global_years, expiring_within: EXPIRING_WITHIN_DAYS).
          sort_by { |row| [row[:last_activity_on], row[:destination_id]] }
      end
    end

    # Expired Records: the mark/unmark log, newest first
    def expired
      @destination_client_id = params[:destination_client_id].to_i if params[:destination_client_id].present?
      @entries = GrdaWarehouse::ClientRetentionLogEntry.order(created_at: :desc, id: :desc)
      @entries = @entries.where(destination_client_id: @destination_client_id) if @destination_client_id
    end

    # Retention Run History
    def runs
      @runs = GrdaWarehouse::ClientRetentionRun.order(started_at: :desc, id: :desc)
    end

    private def set_global_years
      @global_years = GrdaWarehouse::Config.get(:client_retention_years)
    end
  end
end
