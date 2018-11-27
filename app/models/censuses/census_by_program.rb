module Censuses
  class CensusByProgram < ProgramBase

    # what projects should be included?
    def root_projects_scope
      GrdaWarehouse::Hud::Project.all
    end

    # what data should be included?
    def root_data_scope
      GrdaWarehouse::Census::ByProject.all
    end

    # what data should appear in the detail view?
    def census_scope
      GrdaWarehouse::Census::ByProjectClient.all
    end

    # where to find enrollment information for the detail view
    def enrollment_scope
      GrdaWarehouse::ServiceHistoryEnrollment.all
    end
  end
end