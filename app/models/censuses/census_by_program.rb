###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusByProgram < ProgramBase
    # what projects should be included?
    def census_projects_scope(user:)
      GrdaWarehouse::Hud::Project.residential.
        viewable_by(user).
        order(:data_source_id, :OrganizationID)
    end

    # what data should be included?
    def census_data_scope(user:)
      GrdaWarehouse::Census::ByProject.all.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
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
