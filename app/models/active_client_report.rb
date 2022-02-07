###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ActiveClientReport
  include ClientDetailReport
  include Filter::FilterScopes
  include ArelHelper

  def initialize(filter:, user:)
    @user = user
    @filter = filter
  end

  def enrollments
    @enrollments ||= active_client_service_history
  end

  def clients
    @clients ||= GrdaWarehouse::Hud::Client.where(id: enrollments.keys).
      preload(:source_clients).
      index_by(&:id)
  end

  def service_history_columns
    {
      client_id: she_t[:client_id],
      project_id: she_t[:project_id],
      first_date_in_program: she_t[:first_date_in_program],
      last_date_in_program: she_t[:last_date_in_program],
      project_name: she_t[:project_name],
      project_type: she_t[service_history_source(@user).project_type_column],
      organization_id: she_t[:organization_id],
      first_name: c_t[:FirstName],
      last_name: c_t[:LastName],
      enrollment_group_id: she_t[:enrollment_group_id],
      destination: she_t[:destination],
      living_situation: e_t[:LivingSituation],
      ethnicity: c_t[:Ethnicity],
    }.merge(GrdaWarehouse::Hud::Client.race_fields.map { |f| [f.to_sym, c_t[f]] }.to_h)
  end

  def active_client_service_history
    enrollment_scope.pluck(*service_history_columns.values).
      map do |row|
      Hash[service_history_columns.keys.zip(row)]
    end.
      group_by { |m| m[:client_id] }
  end

  private def enrollment_scope
    residential_service_history_source.joins(:client, :enrollment).
      with_service_between(start_date: @filter.start, end_date: @filter.end).
      open_between(start_date: @filter.start, end_date: @filter.end).
      distinct.
      order(first_date_in_program: :asc)
  end

  def residential_service_history_source
    @project_types = @filter.project_type_ids
    scope = history_scope(service_history_source(@user).residential, @filter.sub_population)
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
end
