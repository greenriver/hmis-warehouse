###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class ProgramReport < GrdaWarehouseBase
    include MaReports::CsgEngage::Concerns::HasReportStatus

    self.table_name = :csg_engage_program_reports
    belongs_to :report, class_name: 'MaReports::CsgEngage::Report'
    belongs_to :program, class_name: 'MaReports::CsgEngage::Program'
    has_many :program_mappings, through: :program

    def reset
      update(
        started_at: Time.zone.now,
        failed_at: nil,
        completed_at: nil,
        raw_result: nil,
        json_result: nil,
        error_data: nil,
        warning_data: nil,
      )
    end

    def run
      reset

      cleanup_last_report

      results = []

      (0..(program.households_scope.count / batch_size)).each do |batch_index|
        data = MaReports::CsgEngage::ReportComponents::Report.new(program, batch_size: batch_size, batch_index: batch_index).serialize
        results << MaReports::CsgEngage::Credential.first.post(data)
      end

      update(
        completed_at: Time.zone.now,
        raw_result: results,
        json_result: JSON.parse(results),
        imported_program_name: program.csg_engage_name,
        imported_import_keyword: program.csg_engage_import_keyword,
      )
      report.respond_to_program_report_update(reload)
    rescue Net::ReadTimeout
      update(
        completed_at: Time.zone.now,
        raw_result: nil,
        json_result: nil,
        imported_program_name: program.csg_engage_name,
        imported_import_keyword: program.csg_engage_import_keyword,
      )
      report.respond_to_program_report_update(reload)
    end

    def delete_from_csg
      MaReports::CsgEngage::Credential.first.delete(
        agency_id: program.agency.csg_engage_agency_id,
        program_name: imported_program_name,
        import_keyword: imported_import_keyword,
      )
      update(cleared_at: Time.zone.now)
    end

    def cleanup_last_report
      report.last_report&.program_reports&.find_by(program_id: program_id)&.delete_from_csg
    end

    def completed_without_response?
      completed? && raw_result.nil?
    end

    def other_status_text
      return 'Completed without response' if completed_without_response?
    end

    def batch_size
      1000
    end
  end
end
