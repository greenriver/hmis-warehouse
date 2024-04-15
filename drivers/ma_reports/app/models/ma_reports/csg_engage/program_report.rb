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

      # Check household data with previous values, only send updated households
      households = []
      data.dig('Programs', 0, 'Households').each do |hh_data|
        # TODO: Handle using actual HH ID instead of enrollment ID
        fingerprint = MaReports::CsgEngage::HouseholdHistory.fingerprint_for_household_data(hh_data)
        hh_id = hh_data['Household Identifier']
        last_fingerprint = MaReports::CsgEngage::HouseholdHistory.last_fingerprint_for_household(hh_id)
        if last_fingerprint.nil? || fingerprint != last_fingerprint
          MaReports::CsgEngage::HouseholdHistory.find_or_create_by(household_id: hh_id).update(data: hh_data, last_program_report: self)
          households << hh_data
        end
      end
      data['Programs'][0]['Households'] = households

      result = MaReports::CsgEngage::Credential.first.post(data)
      update(
        completed_at: Time.zone.now,
        raw_result: result,
        json_result: JSON.parse(result),
      )
    end
  end
end
