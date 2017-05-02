module Reports::SystemPerformance::Fy2015
  class Base < Report
    def self.report_name
      'HUD System Performance Reports - FY 2015'
    end

    def download_type
      :csv
    end
  end
end