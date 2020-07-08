###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ReEntryController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      # limit enrollments to only those who are re-entries
      re_entry_enrollment_ids = reporting_class.re_entry.distinct.pluck(:enrollment_id)

      @enrollments = enrollment_scope.
        entry_within_date_range(start_date: @filter.start, end_date: @filter.end).
        where(id: re_entry_enrollment_ids)

      # limit to chosen organizations and projects
      @enrollments = @enrollments.in_project_type(@filter.project_type_ids)
      @enrollments = filter_for_organizations(@enrollments)
      @enrollments = filter_for_projects(@enrollments)
      @enrollments = filter_for_age_ranges(@enrollments)
      @enrollments = filter_for_hoh(@enrollments)
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

    private def filter_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :heads_of_household,
        :ph,
        age_ranges: [],
        organization_ids: [],
        project_ids: [],
        project_type_codes: [],
      )
    end
  end
end
