# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter
#
# Allow us to use the existing report form to filter SPM reports. Needed since the existing form filters
# ServiceHistoryEnrollments but the SPM report operates on raw HUD data
module HudSpmReport::Adapters
  class ServiceHistoryEnrollmentFilter
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(report_instance)
      spm_project_types = HudHelper.util.spm_project_type_numbers
      @filter = Filters::HudFilterBase.new(user: report_instance.user, relevant_project_types: spm_project_types).update(report_instance.options)
      # Enforce the spm project types in addition to chosen project ids
      @project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: spm_project_types, id: report_instance.project_ids).pluck(:id)
    end

    def enrollment_batches(enrollment_scope)
      report_start_date = @filter.start
      report_end_date = @filter.end
      lookback_start_date = report_start_date - 7.years
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:client, :project, enrollment: :client).
        open_between(start_date: lookback_start_date, end_date: report_end_date).
        where(p_t[:id].in(@project_ids))

      # ATTN: coc filter is needed for testkit
      scope = filter_for_cocs(scope)
      scope = @filter.apply_criteria(scope, tags: [:warehouse, :client])

      scope.joins(:enrollment).select(e_t[:id]).in_batches do |batch|
        yield enrollment_scope.where(id: batch.map(&:id))
      end
    end
  end
end
