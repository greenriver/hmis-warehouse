module Censuses
  class CensusBedNightProgram < ProgramBase

    # what projects should be included in graphs?
    def census_projects_scope
      GrdaWarehouse::Hud::Project.night_by_night
    end

    # what data should be included in graphs?
    def census_data_scope
      GrdaWarehouse::Census::ByProject.night_by_night
    end

    # what data should appear in the detail view?
    def census_client_ids_scope
      GrdaWarehouse::Census::ByProjectClient.night_by_night
    end

    # where to find enrollment information for the detail view
    def enrollment_details_scope
      GrdaWarehouse::ServiceHistoryEnrollment.night_by_night
    end

  end
end