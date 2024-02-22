###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class MhmrCaseManagementNoteLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'mhmr_service_start_time', label: 'Start Time:', field_type: 'string', repeats: false },
      { key: 'mhmr_service_end_time', label: 'End Time:', field_type: 'string', repeats: false },
      { key: 'mhmr_service_duration', label: 'Service Duration:', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_name', label: 'Staff Name:', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_id', label: 'Staff ID#', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_credentials', label: 'Staff Credentials:', field_type: 'string', repeats: false },
      { key: 'mhmr_encounter_location', label: 'Location of Specific Encounter, Reason for this Specific Encounter (Immediate Need), and Persons Involved.', field_type: 'string', repeats: false },
      { key: 'mhmr_recovery_plan_goal', label: 'Recovery Plan Goal which was the focus of the MH Case Management Service', field_type: 'string', repeats: false },
      { key: 'mhmr_goals_and_actions', label: 'What goals and actions were required to address the need? What was the plan of action?', field_type: 'string', repeats: false },
      { key: 'mhmr_referring_linking', label: 'Referring', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_referring_linking_narrative', label: 'Referring, linking narrative:', field_type: 'string', repeats: false },
      { key: 'mhmr_referring_advocating', label: 'Advocating', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_advocating_linking_narrative', label: 'Advocating, linking narrative:', field_type: 'string', repeats: false },
      { key: 'mhmr_monitoring', label: 'Monitoring of previous case management activities:', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_monitoring_narrative', label: 'Monitoring narrative:', field_type: 'string', repeats: false },
      { key: 'mhmr_other_assistance', label: 'Other assistance provided:', field_type: 'boolean', repeats: false },
      { key: 'mhmr_other_assistance_narrative', label: 'Other assistance provided narrative:', field_type: 'string', repeats: false },
      { key: 'mhmr_client_behavior_during_service', label: 'Document Client behavior occurring during the service:', field_type: 'string', repeats: false },
      { key: 'mhmr_plan_to_proceed', label: 'What is the plan to proceed?', field_type: 'string', repeats: false },
      { key: 'mhmr_plan_to_proceed_timeline', label: 'Timeline for above plan in order to re-evaluate the needed services:', field_type: 'string', repeats: false },
      { key: 'mhmr_plan_to_proceed_resolution', label: 'Resolution of current need presented (explain):', field_type: 'string', repeats: false },
      { key: 'mhmr_progress_towards_goals', label: 'Progress lack of progress narrative', field_type: 'string', repeats: false },
      { key: 'mhmr_no_show', label: 'No show', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_signature', label: 'Staff Signature / Credentials / ID#:', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_1', label: 'Location Code Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_1', label: 'Activity Code Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_1', label: 'Project Number Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_1', label: 'Start / Stop Time Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_1', label: 'Start / Stop Time Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_1', label: 'Recipient Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_1', label: 'Attendance Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_1', label: 'Number of Recipients Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_1', label: 'Recipient Time Row 1', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_1', label: 'LOF Row 1', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_2', label: 'Location Code Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_2', label: 'Activity Code Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_2', label: 'Project Number Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_2', label: 'Start / Stop Time Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_2', label: 'Start / Stop Time Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_2', label: 'Recipient Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_2', label: 'Attendance Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_2', label: 'Number of Recipients Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_2', label: 'Recipient Time Row 2', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_2', label: 'LOF Row 2', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_3', label: 'Location Code Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_3', label: 'Activity Code Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_3', label: 'Project Number Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_3', label: 'Start / Stop Time Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_3', label: 'Start / Stop Time Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_3', label: 'Recipient Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_3', label: 'Attendance Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_3', label: 'Number of Recipients Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_3', label: 'Recipient Time Row 3', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_3', label: 'LOF Row 3', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_4', label: 'Location Code Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_4', label: 'Activity Code Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_4', label: 'Project Number Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_4', label: 'Start / Stop Time Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_4', label: 'Start / Stop Time Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_4', label: 'Recipient Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_4', label: 'Attendance Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_4', label: 'Number of Recipients Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_4', label: 'Recipient Time Row 4', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_4', label: 'LOF Row 4', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_5', label: 'Location Code Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_5', label: 'Activity Code Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_5', label: 'Project Number Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_5', label: 'Start / Stop Time Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_5', label: 'Start / Stop Time Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_5', label: 'Recipient Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_5', label: 'Attendance Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_5', label: 'Number of Recipients Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_5', label: 'Recipient Time Row 5', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_5', label: 'LOF Row 5', field_type: 'string', repeats: false },

      { key: 'mhmr_service_code_location_6', label: 'Location Code Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_activity_code_6', label: 'Activity Code Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_project_no_6', label: 'Project Number Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_start_time_6', label: 'Start / Stop Time Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_stop_time_6', label: 'Start / Stop Time Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_6', label: 'Recipient Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_attendance_6', label: 'Attendance Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_num_recipients_6', label: 'Number of Recipients Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_recipient_time_6', label: 'Recipient Time Row 6', field_type: 'string', repeats: false },
      { key: 'mhmr_service_code_lof_6', label: 'LOF Row 6', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'MHMR-CM.xlsx'
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
      "mhmrcm-eto-#{response_id}"
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
      when 'mhmr_referring_linking', 'mhmr_referring_advocating', 'mhmr_monitoring'
        values.map(&:present?)
      else
        values
      end
    end
  end
end
