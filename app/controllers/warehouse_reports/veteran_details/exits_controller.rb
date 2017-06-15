module WarehouseReports::VeteranDetails
  class ExitsController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!
    before_action :require_can_view_clients!

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      # Also handle month based requests from javascript
      if params[:month].present?
        month = params.permit(:month)
        @range = DateRange.new(
          start: Date.strptime(month[:month], "%B %Y").beginning_of_month,
          end: Date.strptime(month[:month], "%B %Y").end_of_month,
        )
      else
        @range = DateRange.new(date_range_options)
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

      @clients = exits_from_homelessness.
        ended_between(start_date: @range.start, end_date: @range.end + 1.day).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          include_exit = true
          include_exit = HUD.permanent_destinations.include?(row[:destination]) if params[:ph].present?
          row[:include] = include_exit
          row[:destination] = 99 unless HUD.valid_destinations.keys.include?(row[:destination]) if include_exit
          @buckets[row[:destination]] += 1 if include_exit
        end
      if params[:ph].present?
        @clients.select!{|m| m[:include]}
      end
    end

     def exits_from_homelessness
      GrdaWarehouse::ServiceHistory.exit.
        joins(:client).
        where(
          project_type: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end

    def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end

    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end
  end
end