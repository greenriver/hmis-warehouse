module WarehouseReports
  class ChronicHousedController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!
    before_action :set_range

    def index
      @clients = []
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

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def chronic_source
      GrdaWarehouse::Chronic
    end
  end
end