###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class MhmrRehabilitationNoteLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'mhmr_service_start_time', label: 'Service start time:', field_type: 'string', repeats: false },
      { key: 'mhmr_service_end_time', label: 'Service end time:', field_type: 'string', repeats: false },
      { key: 'mhmr_service_duration', label: 'Duration of service:', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_name', label: 'Staff name:', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_id', label: 'Staff ID#', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_credentials', label: 'Staff credentials:', field_type: 'string', repeats: false },
      { key: 'mhmr_curriculum_utilized', label: 'Curriculum Utilized', field_type: 'string', repeats: true },
      { key: 'mhmr_other_curriculum_utilized', label: 'Other curriculum utilized:', field_type: 'string', repeats: false },
      { key: 'mhmr_copsd_addressed', label: 'Was COPSD addressed in this service?', field_type: 'string', repeats: false },
      { key: 'mhmr_stage_of_change', label: 'Current stage of change exhibited during service:', field_type: 'string', repeats: false },
      { key: 'mhmr_supports_utilized', label: 'Natural Supports Utilized:', field_type: 'string', repeats: false },
      { key: 'mhmr_linked_to', label: 'Linked (Text)', field_type: 'string', repeats: false },
      { key: 'mhmr_wellness_plan_issue', label: 'Wellness Plan Issue to be Addressed:', field_type: 'string', repeats: false },
      { key: 'mhmr_description_of_services', label: 'Description of Services (what you did, how you did it, and the method used)', field_type: 'string', repeats: false },
      { key: 'mhmr_client_response', label: "Response: (The client's response to the services you provided)", field_type: 'string', repeats: false },
      { key: 'mhmr_progress', label: 'Progress or Lack of Progress: (Toward the goal or measurable outcomes, as it relates to the wellness plan)', field_type: 'string', repeats: false },
      { key: 'mhmr_followup_comments', label: 'Follow-Up / Comments:', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'MHMR-Rehab.xlsx'
    end

    def cded_configs
      CDED_CONFIGS +
        (1..6).map do |i|
          [
            { key: "mhmr_service_code_location_#{i}", label: "Location Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_activity_code_#{i}", label: "Activity Code Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_project_no_#{i}", label: "Project Number Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_start_time_#{i}", label: "Start / Stop Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_stop_time_#{i}", label: "Start / Stop Time Row #{i}", field_type: 'string', repeats: false },
          ]
        end.flatten
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "mhmr-rehab-eto-#{response_id}"
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
      else
        values
      end
    end

    def form_definition_identifier
      'mhmr-rehabilitation-note'
    end
  end
end
