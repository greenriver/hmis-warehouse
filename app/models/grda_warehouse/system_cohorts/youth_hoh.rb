###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class YouthHoh < CurrentlyHomeless
    def cohort_name
      'Youth (under 25) and Head of Household'
    end

    private def enrollment_source
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: youth_and_hoh_client_ids)

      # Optionally filter the cohort by project group
      project_group = ::GrdaWarehouse::Config.get(:youth_hoh_cohort_project_group_id)
      return scope unless project_group.present?

      project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group).
        joins(:projects).
        pluck(:project_id)
      scope.in_project(project_ids)
    end
  end
end
