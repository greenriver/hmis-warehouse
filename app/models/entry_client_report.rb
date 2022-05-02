###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class EntryClientReport
  include ClientDetailReport
  include Filter::FilterScopes
  include ArelHelper

  def initialize(filter:, user:)
    @user = user
    @filter = filter
  end

  def enrollments
    @enrollments ||= enrollments_by_client
  end

  def buckets
    @buckets ||= bucket_clients(enrollments)
  end

  def data
    @data ||= setup_data_structure
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
      joins(:client, project: :organization).
      includes(:client, project: :organization).
      where(client_id: involved_client_ids).
      where(she_t[:first_date_in_program].lteq(@filter.end)).
      in_project_type(@filter.project_type_ids).
      order(first_date_in_program: :desc).
      group_by { |row| row[:client_id] }
  end

  def service_history_source
    GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(@user))
  end

  def homeless_service_history_source
    @project_types = @filter.project_type_ids
    scope = history_scope(service_history_source.in_project_type(@filter.project_type_ids), @filter.sub_population)
    scope = filter_for_project_type(scope)
    scope = filter_for_organizations(scope)
    scope = filter_for_projects(scope)
    scope = filter_for_age(scope)
    scope = filter_for_head_of_household(scope)
    scope = filter_for_cocs(scope)
    scope = filter_for_gender(scope)
    scope = filter_for_race(scope)
    scope = filter_for_ethnicity(scope)
    scope
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
end
