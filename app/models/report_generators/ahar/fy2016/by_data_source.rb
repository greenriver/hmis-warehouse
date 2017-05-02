# This version of the AHAR report is scoped to a particular project at a particular data source
module ReportGenerators::Ahar::Fy2016
  class ByDataSource < Base
    def report_class
      Reports::Ahar::Fy2016::ByDataSource
    end

    def initialize options
      @data_source_id = options[:data_source_id]
      @report_start = options[:report_start].to_time.strftime("%Y-%m-%d")
      @report_end = options[:report_end].to_time.strftime("%Y-%m-%d")
    end

    private def involved_entries_scope
      super.where(data_source_id: @data_source_id)
    end
  end
end