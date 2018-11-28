module Censuses
  class CensusByProgram < ProgramBase

    # what projects should be included?
    def census_projects_scope
      GrdaWarehouse::Hud::Project.all
    end

    # what data should be included?
    def census_data_scope
      GrdaWarehouse::Census::ByProject.all
    end

    # what data should appear in the detail view?
    def census_client_ids_scope
      GrdaWarehouse::Census::ByProjectClient.all
    end

    # where to find enrollment information for the detail view
    def enrollment_details_scope
      GrdaWarehouse::ServiceHistoryEnrollment.all
    end
  end
end