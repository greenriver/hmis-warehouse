module ReportResultsSummaries::Lsa
  class Base < ReportResultsSummary
    def report_download_format
      :zip
    end
  end
end