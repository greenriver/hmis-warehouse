###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ExternalFormSubmission < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements

    available_filter_options do
      arg :status, HmisSchema::Enums::ExternalFormSubmissionStatus
      arg :include_spam, Boolean
      arg :submitted_date, GraphQL::Types::ISO8601Date
    end

    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam, Boolean, null: true
    field :status, HmisSchema::Enums::ExternalFormSubmissionStatus, null: false
    field :notes, String, null: true
    field :definition, Forms::FormDefinition, null: false
    field :values, GraphQL::Types::JSON, null: true
    custom_data_elements_field # Resolve for backwards compatibility. Can remove in a future release
    field :enrollment_id, ID, null: true, description: 'Enrollment that was generated from this submission, if any'
    field :client_id, ID, null: true, description: 'Client that was generated from this submission, if any'
    field :summary_fields, [HmisSchema::KeyValue], null: false, description: 'Key/value responses for certain summary-level form questions'

    def definition
      load_ar_association(object, :definition)
    end

    def values
      # Unlike CustomAssessments, which display on the frontend using the created CDEs once they've been submitted,
      # ExternalFormSubmissions always display using the values from raw_data. Example: If the form processor created
      # a client, and then a user manually updates the client's name in HMIS, the form review UI should still display
      # the client name that was originally submitted with the form.
      object.form_values
    end

    # "Summary" fields are a subset of the form's fields that are displayed on the external forms review table.
    # Includes Client first/last name plus any CDEDs where show_in_summary is true.
    def summary_fields
      cdeds_by_key = load_ar_association(definition, :custom_data_element_definitions).
        select(&:show_in_summary).
        index_by(&:key).stringify_keys

      cded_keys = cdeds_by_key.keys

      object.form_values.map do |key, value|
        case key.to_s
        when 'Client.firstName'
          OpenStruct.new(id: 'first', key: 'First Name', value: value)
        when 'Client.lastName'
          OpenStruct.new(id: 'last', key: 'Last Name', value: value)
        when *cded_keys
          cded = cdeds_by_key[key]
          OpenStruct.new(id: cded.id, key: cded.label, value: value)
        end
      end.compact.sort_by(&:key)
    end

    def client_id
      enrollment = load_ar_association(object, :enrollment)
      return unless enrollment

      load_ar_association(enrollment, :client)&.id
    end
  end
end
