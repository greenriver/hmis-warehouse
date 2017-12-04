module WarehouseReports
  class ChronicHousedController < WarehouseReportsController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @clients = client_source.joins(:source_projects, :permanent_source_exits_from_homelessness, :chronics).
        where(
          ex_t[:ExitDate].gt(@range.start).
          and(ex_t[:Destination].in(::HUD.permanent_destinations))
        ).
        where(chronics: {date: @range.range}).
        order(ex_t[:ExitDate].asc).
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
        exit_date: ex_t[:ExitDate].as('exit_date').to_sql,
        destination: ex_t[:Destination].as('destination').to_sql,
        chronic_date: ch_t[:date].as('date').to_sql,
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

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/chronic_housed')
    end
  end
end
