module HudReports::Ahar::Fy2017
  class DataSourceController < BaseController
   
    def report_source
      Reports::Ahar::Fy2017::ByDataSource
    end

  end
end