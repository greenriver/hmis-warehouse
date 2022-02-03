###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class CanceledMatchesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @matches = report_source.
        canceled_between(start_date: @range.start, end_date: @range.end + 1.day).
        order(match_started_at: :asc)
      @all_steps = report_source.
        where(match_id: @matches.select(:match_id)).
        order(decision_order: :asc).
        group_by(&:match_id)
    end

    def set_range
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 13.month.ago.to_date,
          end: 1.months.ago.to_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end

    def report_source
      GrdaWarehouse::CasReport
    end
  end
end
