###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusByProgram < ProgramBase
    # what projects should be included?
    def census_projects_scope
      scope = GrdaWarehouse::Hud::Project.residential.
        viewable_by(@filter.user).
        where(id: @filter.effective_project_ids)

      # Limit ES projects to Night-by-night only by filtering out Entry/Exit ES projects
      scope = scope.where.not(ProjectType: 1, TrackingMethod: 0) if @filter.limit_es_to_nbn
      scope
    end

    # what data should be included?
    def census_data_scope(project_scope)
      GrdaWarehouse::Census::ByProject.joins(:project).merge(project_scope)
    end

    # # what data should appear in the detail view?
    # def census_client_ids_scope
    #   GrdaWarehouse::Census::ByProjectClient.all
    # end

    # where to find enrollment information for the detail view
    def enrollment_details_scope
      GrdaWarehouse::ServiceHistoryEnrollment.residential
    end
  end
end
