###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class ProgramReport < GrdaWarehouseBase
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
      result = MaReports::CsgEngage::Credential.first.post(data)
      update(
        completed_at: Time.zone.now,
        raw_result: result,
        json_result: JSON.parse(result),
      )
    end
  end
end
