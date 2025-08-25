# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#
# ActiveClientReport
# Determines which clients are "active" within a user-supplied date range for the
# Client Details → Actives report.
#
# Definition of "active" (HUD Active Client Method 5, augmented for street outreach):
# - The client has an enrollment that is open at any time between filter.start and filter.end; and
# - The client has qualifying activity within the same window:
#   - Emergency Shelter — Non-Bed-Night (ES-NBN): requires at least one service during the window.
#     Enrollments in ES-NBN without services are excluded.
#   - Street Outreach (SO): requires CLS present and valid
#   - For other entry/exit projects types, only require an enrollment overlapping the reporting window
#
# Inclusion and exclusion rules:
# - Qualifying events/CLS must fall within BOTH the enrollment dates and the report window.
# - ES-NBN enrollments with no services in-range are excluded.
#
# This logic is kept aligned with behavior in other reports when "require services" is enabled.
#
# See also
# * GrdaWarehouse::Tasks::ServiceHistory::Enrollment
#
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
      with_service_between(start_date: @filter.start, end_date: @filter.end).
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
