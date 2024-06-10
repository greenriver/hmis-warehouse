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
    belongs_to :program_mapping, class_name: 'MaReports::CsgEngage::ProgramMapping'

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

      data = MaReports::CsgEngage::ReportComponents::Report.new(program_mapping).serialize
      cleanup_last_report
      result = MaReports::CsgEngage::Credential.first.post(data)
      update(
        completed_at: Time.zone.now,
        raw_result: result,
        json_result: JSON.parse(result),
        imported_program_name: program_mapping.csg_engage_name,
        imported_import_keyword: program_mapping.csg_engage_import_keyword,
      )
      report.respond_to_program_report_update(reload)
    end

    def delete_from_csg
      MaReports::CsgEngage::Credential.first.delete(
        agency_id: program_mapping.agency.csg_engage_agency_id,
        program_name: imported_program_name,
        import_keyword: imported_import_keyword,
      )
      update(cleared_at: Time.zone.now)
    end

    def cleanup_last_report
      report.last_report&.program_reports&.find_by(program_mapping_id: program_mapping_id)&.delete_from_csg
    end
  end
end