module HudReports::Ahar::Fy2017
  class ProjectController < BaseController
   
    def report_source
      Reports::Ahar::Fy2017::ByProject
    end

  end
end