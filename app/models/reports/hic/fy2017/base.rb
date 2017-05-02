module Reports::Hic::Fy2017
  class Base < Report
    def self.report_name
      'HIC - FY 2017'
    end

    def continuum_name
      'Boston Continuum of Care'
    end

    def download_type
      nil
    end

    def has_options?
      false
    end

    def results_path
      reports_hic_export_path
    end
  end
end