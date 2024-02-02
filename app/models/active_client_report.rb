###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ActiveClientReport
  include ClientDetailReport
  include Filter::FilterScopes
  include ArelHelper
  attr_reader :filter

  def initialize(filter:, user:)
    @user = user
    @filter = filter
  end

  def self.url
    'warehouse_reports/client_details/actives'
  end

  def self.viewable_by(user)
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
      viewable_by(user).exists?
  end

  def key_for_display(key)
    key.to_s.humanize
  end

  def value_for_display(_key, value)
    value
  end

  def enrollments
    @enrollments ||= active_client_service_history
  end

  def clients
    @clients ||= GrdaWarehouse::Hud::Client.where(id: enrollments.keys).
      preload(:source_clients).
      index_by(&:id)
  end

  def active_client_service_history
    enrollment_scope.distinct.group_by(&:client_id)
  end

  private def enrollment_scope
    residential_service_history_source.joins(:client, :enrollment, :project).
      includes(:client, :enrollment, :project).
      with_service_between(start_date: @filter.start, end_date: @filter.end).
      open_between(start_date: @filter.start, end_date: @filter.end).
      distinct.
      order(first_date_in_program: :asc)
  end

  def residential_service_history_source
    @project_types = @filter.project_type_ids
    scope = history_scope(service_history_source(@user), @filter.sub_population)
    scope = filter_for_project_type(scope)
    scope = filter_for_organizations(scope)
    scope = filter_for_projects(scope)
    scope = filter_for_age(scope)
    scope = filter_for_head_of_household(scope)
    scope = filter_for_cocs(scope)
    scope = filter_for_gender(scope)
    scope = filter_for_race(scope)
    scope
  end
end
