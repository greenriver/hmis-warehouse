###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class ReEntryController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    before_action :set_limited, only: [:index]
    before_action :set_projects
    before_action :set_organizations
    before_action :set_sub_population
    before_action :set_project_types

    def index
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)

      @start_date = @range.start
      @end_date = @range.end

      # limit enrollments to only those who are re-entries
      re_entry_enrollment_ids = reporting_class.re_entry.distinct.pluck(:enrollment_id)

      @enrollments = enrollment_scope.
        entry_within_date_range(start_date: @start_date, end_date: @end_date).
        where(id: re_entry_enrollment_ids)

      # limit to chosen organizations and projects
      @enrollments = @enrollments.merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?
      @enrollments = @enrollments.merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)) if @project_ids.any?

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
      enrollment_source.entry.joins(:project, :organization).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(:project, :organization, :client)
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def reporting_class
      @reporting_class ||= Reporting::MonthlyReports::Base.class_for @sub_population
    end

    def set_organizations
      @organization_ids = begin
                            params[:range][:organization_ids].map(&:presence).compact.map(&:to_i)
                          rescue StandardError
                            []
                          end
    end

    def set_projects
      @project_ids = begin
                       params[:range][:project_ids].map(&:presence).compact.map(&:to_i)
                     rescue StandardError
                       []
                     end
    end

    def set_sub_population
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
    end

    def set_project_types
      @project_type_codes = params[:range].try(:[], :project_types)&.map(&:presence)&.compact&.map(&:to_sym) || [:es, :sh, :so, :th]
      @project_types = []
      @project_type_codes.each do |code|
        @project_types += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[code]
      end
    end
  end
end
