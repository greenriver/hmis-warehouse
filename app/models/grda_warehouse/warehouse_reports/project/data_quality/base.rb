module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class Base < GrdaWarehouseBase
    self.table_name = :project_data_quality
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name
    has_many :project_contacts, through: :project
    has_many :report_tokens, -> { where(report_id: id)}, class_name: GrdaWarehouse::ReportToken.name

    def display

    end

    def print

    end

    def run!
      started_at = Time.now
    end

    def send_notifications
      ProjectDataQualityReportMailer.report_complete(project, self).deliver_later
    end
  end
end