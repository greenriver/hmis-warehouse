module WarehouseReports
  class ChronicHousedController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @chronics = chronic_source.where(date: @range.range).group_by(&:client_id)
      @clients = client_source.joins(:service_history_enrollments).
        where(
          she_t[:last_date_in_program].gt(@range.start).
          and(she_t[:destination].in(::HUD.permanent_destinations))
        ).
        where(id: @chronics.keys).
        order(she_t[:last_date_in_program].asc).
        distinct.
        pluck(*columns.values).
        map do |row|
          ::OpenStruct.new(Hash[columns.keys.zip(row)])
        end.group_by do |row|
          row[:client_id]
        end
    end

    def columns
      {
        client_id: c_t[:id].as('client_id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        exit_date: she_t[:last_date_in_program].as('exit_date').to_sql,
        destination: she_t[:destination].as('destination').to_sql,
      }
    end

    def set_range
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 3.month.ago.to_date,
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
