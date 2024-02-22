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

      { key: 'mhmr_service_code_location_1', label: 'Location Code Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_1', label: 'Activity Code Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_1', label: 'Project Number Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_1', label: 'Start / Stop Time Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_1', label: 'Start / Stop Time Row 1', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_2', label: 'Location Code Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_2', label: 'Activity Code Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_2', label: 'Project Number Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_2', label: 'Start / Stop Time Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_2', label: 'Start / Stop Time Row 2', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_3', label: 'Location Code Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_3', label: 'Activity Code Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_3', label: 'Project Number Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_3', label: 'Start / Stop Time Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_3', label: 'Start / Stop Time Row 3', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_4', label: 'Location Code Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_4', label: 'Activity Code Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_4', label: 'Project Number Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_4', label: 'Start / Stop Time Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_4', label: 'Start / Stop Time Row 4', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_5', label: 'Location Code Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_5', label: 'Activity Code Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_5', label: 'Project Number Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_5', label: 'Start / Stop Time Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_5', label: 'Start / Stop Time Row 5', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_6', label: 'Location Code Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_6', label: 'Activity Code Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_6', label: 'Project Number Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_6', label: 'Start / Stop Time Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_6', label: 'Start / Stop Time Row 6', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'MHMR-Non-Billable.xlsx'
    end

    def cded_configs
      CDED_CONFIGS
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
