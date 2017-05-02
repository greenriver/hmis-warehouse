# This version of the AHAR report is scoped to a particular project at a particular data source
module ReportGenerators::Pit::Fy2017
  class ByProject < Base
    def report_class
      Reports::Pit::Fy2017::ByProject
    end

    def initialize options
      super
      @project_id = options[:project]
      @data_source_id = options[:data_source_id]
      Rails.logger.info "Project #{@project_id} DS: #{@data_source_id}"
    end

    private def service_history_scope
      super.where(
        project_id: @project_id, 
        data_source_id: @data_source_id
      )
    end
  end
end