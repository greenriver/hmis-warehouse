module Censuses
  class CensusBedNightProgram < ProgramBase
    # what projects should be included?
    def root_projects_scope
      GrdaWarehouse::Hud::Project.night_by_night
    end

    # what data should be included?
    def root_data_scope
      GrdaWarehouse::Census::ByProject.night_by_night
    end
  end
end