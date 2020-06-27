###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusAllEs < ProgramBase
    # what projects should be included in graphs?
    def census_projects_scope(user:)
      GrdaWarehouse::Hud::Project.es.viewable_by(user)
    end

    # what data should be included in graphs?
    def census_data_scope(user:)
      GrdaWarehouse::Census::ByProject.es.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    # # what data should appear in the detail view?
    # def census_client_ids_scope
    #   GrdaWarehouse::Census::ByProjectClient.es
    # end

    # where to find enrollment information for the detail view
    def enrollment_details_scope
      GrdaWarehouse::ServiceHistoryEnrollment.es
    end
  end
end
