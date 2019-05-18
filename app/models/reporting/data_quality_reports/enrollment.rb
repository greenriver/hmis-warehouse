# A reporting table to power the enrollment related answers for project data quality reports.

module Reporting::DataQualityReports
  class Enrollment < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_data_quality_report_enrollments

  end
end