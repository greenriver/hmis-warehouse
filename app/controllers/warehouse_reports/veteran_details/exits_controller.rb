module WarehouseReports::VeteranDetails
  class ExitsController < ApplicationController
    include ArelHelper

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      # Also handle month based requests from javascript
      if params[:month].present?
        month = params.permit(:month)
        @range = ::Filters::DateRange.new(
          start: Date.strptime(month[:month], "%B %Y").beginning_of_month,
          end: Date.strptime(month[:month], "%B %Y").end_of_month,
        )
      else
        @range = ::Filters::DateRange.new(date_range_options)
      end
      columns = {
        client_id: sh_t[:client_id].as('client_id').to_sql,
        date: sh_t[:date].as('date').to_sql, 
        destination: sh_t[:destination].as('destination').to_sql, 
        first_name: c_t[:FirstName].as('first_name').to_sql, 
        last_name: c_t[:LastName].as('last_name').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
      }
      @buckets = Hash.new(0)

      @clients = exits_from_homelessness
      if params[:ph]
        @clients = @clients.where(destination: HUD.permanent_destinations)
      end
      @clients = @clients.ended_between(start_date: @range.start, end_date: @range.end + 1.day).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          destination = row[:destination]
          destination = 99 unless HUD.valid_destinations.keys.include?(row[:destination])
          @buckets[destination] += 1
        end

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        where(
          service_history_source.project_type_column => GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/really_old_enrollments')
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end
  end
end
