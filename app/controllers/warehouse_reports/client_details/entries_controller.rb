###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::ClientDetails
  class EntriesController < ApplicationController
    include ArelHelper
    include ApplicationHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_limited, only: [:index]
    before_action :set_filter

    CACHE_EXPIRY = Rails.env.production? ? 8.hours : 20.seconds

    def index
      @enrollments = enrollments_by_client
      # put clients in buckets
      @buckets = bucket_clients(@enrollments)

      @data = setup_data_structure
      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def service_scope(project_type)
      homeless_service_history_source.
        with_service_between(start_date: @filter.start, end_date: @filter.end).
        in_project_type(project_type)
    end

    def enrollments_by_client
      # limit to clients with an entry within the range and service within the range in the type
      involved_client_ids = homeless_service_history_source.
        entry.
        started_between(start_date: @filter.start, end_date: @filter.end).
        in_project_type(@filter.project_type_ids).
        with_service_between(start_date: @filter.start, end_date: @filter.end).
        distinct.
        select(:client_id)
      # get all of their entry records regardless of date range
      homeless_service_history_source.
        entry.
        joins(:client, :organization).
        where(client_id: involved_client_ids).
        where(she_t[:first_date_in_program].lteq(@filter.end)).
        in_project_type(@filter.project_type_ids).
        order(first_date_in_program: :desc).
        pluck(*entered_columns.values).
        map do |row|
        Hash[entered_columns.keys.zip(row)]
      end.
        group_by { |row| row[:client_id] }
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    def homeless_service_history_source
      scope = history_scope(service_history_source.in_project_type(@filter.project_type_ids), @filter.sub_population)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_age_ranges(scope)
      scope = filter_for_hoh(scope)
      scope
    end

    def entered_columns
      {
        project_type: she_t[service_history_source.project_type_column].as('project_type'),
        first_date_in_program: she_t[:first_date_in_program].as('first_date_in_program'),
        last_date_in_program: she_t[:last_date_in_program].as('last_date_in_program'),
        client_id: she_t[:client_id].as('client_id'),
        project_name: she_t[:project_name].as('project_name'),
        first_name: c_t[:FirstName].as('first_name'),
        last_name: c_t[:LastName].as('last_name'),
        organization_name: o_t[:OrganizationName].as('organization_name'),
      }
    end

    def setup_data_structure
      month_name = @filter.start.to_time.strftime('%B')
      {
        first_time: {
          label: 'First time clients in the project type',
          data: [],
          backgroundColor: '#288BE4',
        },
        less_than_thirty: {
          label: "Clients with an entry in #{month_name} and an entry within 30 days prior to their most recent entry in #{month_name}",
          data: [],
          backgroundColor: '#704C70',
        },
        thirty_to_sixty: {
          label: "Clients with an entry in #{month_name} and between 30 and 60 days prior",
          data: [],
          backgroundColor: '#5672AA',
        },
        sixty_plus: {
          label: "Clients with an entry in #{month_name} and 60+ days prior",
          data: [],
          backgroundColor: '#45789C',
        },
      }
    end

    def bucket_clients(enrollments)
      buckets = {
        sixty_plus: Set.new,
        thirty_to_sixty: Set.new,
        less_than_thirty: Set.new,
        first_time: Set.new,
      }

      enrollments.each do |client_id, entries|
        if entries.count == 1
          buckets[:first_time] << client_id
        else
          days = days_since_last_entry(entries)
          if days < 30
            buckets[:less_than_thirty] << client_id
          elsif (30..60).cover?(days)
            buckets[:thirty_to_sixty] << client_id
          else # days > 60
            buckets[:sixty_plus] << client_id
          end
        end
      end
      buckets
    end

    def days_since_last_entry(enrollments)
      enrollments.first(2).map { |m| m[:first_date_in_program] }.reduce(:-).abs
    end

    private def filter_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :heads_of_household,
        age_ranges: [],
        organization_ids: [],
        project_ids: [],
        project_type_codes: [],
      )
    end
  end
end
