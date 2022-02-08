###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ReEntryController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports
    include Filter::FilterScopes

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      @show_ph_destinations = true
      @project_types = @filter.project_type_ids
      # limit enrollments to only those who are re-entries
      re_entry_enrollment_ids = reporting_class.re_entry.distinct.pluck(:enrollment_id)

      scope = enrollment_scope.
        entry_within_date_range(start_date: @filter.start, end_date: @filter.end).
        where(id: re_entry_enrollment_ids)

      # limit to chosen organizations and projects
      scope = scope.in_project_type(@filter.project_type_ids)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_age(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      @enrollments = filter_for_ethnicity(scope)
      # go back for the re-entries for those we actually have permission to see
      @re_entries = reporting_class.re_entry.where(enrollment_id: @enrollments.pluck(:id)).index_by(&:enrollment_id)

      respond_to do |format|
        format.html do
        end
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def enrollment_scope
      service_history_source.entry.joins(:project, :organization).
        preload(:project, :organization, :client)
    end

    def reporting_class
      @reporting_class ||= Reporting::MonthlyReports::Base.class_for(@filter.sub_population)
    end
  end
end
