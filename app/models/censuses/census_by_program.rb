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

  end
end