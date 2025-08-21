# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# what is active?
# * if you have an enrollment in EE, the client is active if the enrollment is active_client_report
# * for nbn, you can have an open enrollment but no service, ignore those enrollments
# * extrapolated - shs, is added based on a setting for street outreach, adding events for the entire month that the client was (see service history tasks/enrollment where SHS are generated)
#
# the intent is to include active clients within a time-range, where active is either based on services on EE. To be active, a client must have an enrollment and
#
# note inclusion of SHS is conditional based on a filter-option.
#
# it aligns with core-demo query, as long as require services are set

# hud has a concept of active-client for reporting.
# we use method 5 augmented to support street outreach
#  for street outreach, we remove invalid data: Street outreach must have CLS, ES-NBN must have service service. dates for those records must occur both within the enrollment and report range

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

  def enrollment_scope
    base_enrollment_scope.
      distinct.
      order(first_date_in_program: :asc, last_date_in_program: :asc)
  end

  # Base scope used by both listing and counting, without DISTINCT/ORDER
  def base_enrollment_scope
    residential_service_history_source.
      joins(:client, :enrollment, :project).
      with_service_between_prefiltered(start_date: @filter.start, end_date: @filter.end, service_scope: :bed_night).
      open_between(start_date: @filter.start, end_date: @filter.end)
  end

  # Efficient total enrollment count: COUNT(DISTINCT id) without ORDER BY
  def enrollment_count
    she_t = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
    base_enrollment_scope.
      reselect(she_t[:id]).
      distinct.
      reorder(nil).
      count
  end

  # Efficient unique client count over the same filters
  def unique_client_count
    she_t = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
    base_enrollment_scope.
      reselect(she_t[:client_id]).
      distinct.
      reorder(nil).
      count
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
