###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026
  # The earliest head of household enrollment for each household, whose entry date the Annual Assessment
  # section of the HMIS Reporting Glossary uses as the anniversary date, per: in the event a household has
  # more than one head of household active in the report range, (i.e., if the first HoH exited and another
  # household member became the HoH), the later HoH's [project start date] will be back-dated to the first
  # HoH's [project start date].
  #
  # Deliberately ignores the report date range so that a household whose head of household exited before
  # the report period, and where no other member was recorded as the head of household, still has an
  # anniversary. Datalab does the same, calculating annual_assessment_dates from the unfiltered
  # Enrollment table rather than from the enrollments included in the report.
  #
  # HouseholdID is unique only within a data source, so households are matched and keyed on both.
  class HouseholdHohEnrollments
    CTE_NAME = 'report_households'

    def initialize(enrollment_scope:, project_ids:)
      @enrollment_scope = enrollment_scope
      @project_ids = project_ids
    end

    # @return [Hash{Array(Integer, String) => GrdaWarehouse::ServiceHistoryEnrollment}]
    def to_h
      GrdaWarehouse::ServiceHistoryEnrollment.find_by_sql(query).
        group_by { |enrollment| [enrollment.data_source_id, enrollment.household_id] }.
        transform_values { |enrollments| enrollments.min_by(&:first_date_in_program) }
    end

    private

    # MATERIALIZED: as a subquery or inlined CTE, Postgres estimates one row on each side of the
    # Project join and re-runs the household query once per head of household entry.
    def query
      heads_of_households.arel.with(
        Arel::Nodes::Cte.new(CTE_NAME, report_households.arel, materialized: true),
      )
    end

    def report_households
      @enrollment_scope.where.not(household_id: nil).distinct.select(:data_source_id, :household_id)
    end

    def heads_of_households
      she_t = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
      households_t = Arel::Table.new(CTE_NAME)
      join = she_t.join(households_t).on(
        households_t[:data_source_id].eq(she_t[:data_source_id]).
          and(households_t[:household_id].eq(she_t[:household_id])),
      ).join_sources
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.heads_of_households.joins(join)
      scope = scope.in_project(@project_ids) if @project_ids.present?
      scope
    end
  end
end
