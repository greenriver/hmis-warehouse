###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class MhmrNonBillableNoteLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'mhmr_service_start_time', label: 'Start', field_type: 'string', repeats: false },
      { key: 'mhmr_service_end_time', label: 'End', field_type: 'string', repeats: false },
      { key: 'mhmr_service_duration', label: 'Service Duration', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_name', label: 'Staff Name', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_id', label: 'Staff ID#', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_credentials', label: 'Staff Credentials', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_scheduled_appointment', label: 'Scheduled Checkbox', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_dnka', label: 'DNKA Check Box', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_action_taken', label: 'Action taken', field_type: 'string', repeats: false },
      { key: 'mhmr_result', label: 'Result', field_type: 'string', repeats: false },
      { key: 'mhmr_other_notes', label: 'Other Notes', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'MHMR-Non-Billable.xlsx'
    end

    def cded_configs
      CDED_CONFIGS +
        (1..6).map do |i|
          [
            { key: "mhmr_service_code_location_#{i}", label: "Location Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_activity_code_#{i}", label: "Activity Code Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_project_no_#{i}", label: "Project Number Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_start_time_#{i}", label: "Start/Stop Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_stop_time_#{i}", label: "Start/Stop Time Row #{i}", field_type: 'string', repeats: false },
          ]
        end.flatten
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "mhmr-nb-eto-#{response_id}"
    end

    def cde_values(row, config)
      key = config.fetch(:key)
      values = super(row, config)
      case key
        # Time ranges are 2 strings separated by ' - '
      when /mhmr_service_code_start_time/
        values.map { |value| value.present? ? value.split(' - ').first : nil }
      when /mhmr_service_code_stop_time/
        values.map { |value| value.present? ? value.split(' - ').last : nil }
        # Booleans where presence of a string means true
      when 'mhmr_staff_scheduled_appointment', 'mhmr_dnka'
        values.map(&:present?)
      else
        values
      end
    end
  end
end
