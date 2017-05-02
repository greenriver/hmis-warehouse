module ReportResultsSummaries::SystemPerformance
  class Base < ReportResultsSummary
    def report_download_format
      :csv
    end
  end
end