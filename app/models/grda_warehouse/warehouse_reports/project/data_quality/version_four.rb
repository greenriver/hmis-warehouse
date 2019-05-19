module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionFour < Base

    has_many :enrollments, class_name: Reporting::DataQualityReports::Enrollment.name

    def run!
      progress_methods = [
        :start_report,
        :finish_report,
      ]
      progress_methods.each_with_index do |method, i|
        percent = ((i/progress_methods.size.to_f)* 100)
        percent = 0.01 if percent == 0
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        self.send(method)
        Rails.logger.info "Completed #{method}"
      end

    end
  end
end