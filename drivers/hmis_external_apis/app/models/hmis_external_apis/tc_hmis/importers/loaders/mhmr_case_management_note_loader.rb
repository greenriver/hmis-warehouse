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
    ].freeze

    def filename
      'MHMR-CM.xlsx'
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
            { key: "mhmr_service_code_recipient_#{i}", label: "Recipient Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_attendance_#{i}", label: "Attendance Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_num_recipients_#{i}", label: "Number of Recipients Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_recipient_time_#{i}", label: "Recipient Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_lof_#{i}", label: "LOF Row #{i}", field_type: 'string', repeats: false },
          ]
        end.flatten
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

    def yn_boolean(value)
      value == 'Other assistance provided:' ? true : super
    end

    def form_definition_identifier
      'mhmr-case-management-note'
    end
  end
end
