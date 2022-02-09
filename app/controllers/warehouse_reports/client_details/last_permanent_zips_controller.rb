###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::ClientDetails
  class LastPermanentZipsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    before_action :set_limited, only: [:index]

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      # Also handle month based requests from javascript
      if params[:month].present?
        @sub_population = (params.try(:[], :sub_population).presence || :clients).to_sym
        month = params.permit(:month)
        @range = ::Filters::DateRangeWithSubPopulation.new(
          start: Date.strptime(month[:month], '%B %Y').beginning_of_month,
          end: Date.strptime(month[:month], '%B %Y').end_of_month,
          sub_population: @sub_population,
        )
      else
        @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)
      end

      @clients = population_service_history_source.
        joins(:client, :enrollment).
        open_between(start_date: @range.start, end_date: @range.end).
        distinct.
        order(first_date_in_program: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.
        group_by { |row| row[:client_id] }

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def yes_no(bool)
      bool ? 'yes' : 'no'
    end
    helper_method :yes_no

    def columns
      {
        client_id: she_t[:client_id].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        last_permanent_zip: e_t[:LastPermanentZIP].to_sql,
        unaccompanied_youth: she_t[:unaccompanied_youth].to_sql,
        age: she_t[:age].to_sql,
        parenting_youth: she_t[:parenting_youth].to_sql,
        parenting_juvenile: she_t[:parenting_juvenile].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        project_name: p_t[:ProjectName].to_sql,
        head_of_household: she_t[:head_of_household].to_sql,
      }
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    def population_service_history_source
      history_scope(service_history_source, @sub_population)
    end
  end
end
