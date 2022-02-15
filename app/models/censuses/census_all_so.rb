###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusAllSo < ProgramBase
    # what projects should be included in graphs?
    def census_projects_scope(user:)
      GrdaWarehouse::Hud::Project.so.viewable_by(user)
    end

    # what data should be included in graphs?
    def census_data_scope(user:)
      GrdaWarehouse::Census::ByProject.so.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    # # what data should appear in the detail view?
    # def census_client_ids_scope
    #   GrdaWarehouse::Census::ByProjectClient.so
    # end

    # where to find enrollment information for the detail view
    def enrollment_details_scope
      GrdaWarehouse::ServiceHistoryEnrollment.so
    end
  end
end
