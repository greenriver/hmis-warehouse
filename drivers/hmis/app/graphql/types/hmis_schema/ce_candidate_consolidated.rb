###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidateConsolidated < Types::BaseObject
    # object is an Open Struct
    field :id, ID, null: false
    field :client_id, ID, null: true # destination client id
    field :source_client_id, ID, null: true
    field :client_name, String, null: true
    field :unit_group_name, String, null: true
    field :project_name, String, null: true
    field :project_id, ID, null: true
    field :vacancies, Integer, null: false
    field :organization_name, String, null: true
    field :when_added_to_candidate_pool, GraphQL::Types::ISO8601DateTime, null: true
    field :when_updated_in_candidate_pool, GraphQL::Types::ISO8601DateTime, null: true
    field :priority_score, Float, null: true
    # FIXME: known FieldMap keys should be pulled out. only CDEs are fully dynamic
    field :client_attributes, GraphQL::Types::JSON, null: true
    # fixme this should be a CustomDataElement array
    field :custom_data_elements, GraphQL::Types::JSON, null: true, description: 'Custom Data Elements that contributed to eligibility and priority for this candidate pool'
    field :client_age, Integer, null: true
    field :open_enrollment_project_types, [Types::HmisSchema::Enums::ProjectType], null: true
    field :open_referral_project_types, [Types::HmisSchema::Enums::ProjectType], null: true

    # last contact date
    def client_id
      object.destination_client_id
    end

    # add: candidate pool id
    # add: source client id? how to pick, or include all HMIS?
    def client_age
      object.client_attributes.dig('current_age')
    end

    def open_enrollment_project_types
      object.client_attributes.dig('open_enrollment_project_types')
    end

    def open_referral_project_types
      object.client_attributes.dig('open_referral_project_types')
    end

    def custom_data_elements
      lookup = Hmis::Hud::CustomDataElementDefinition.where(owner_type: 'Hmis::Hud::CustomAssessment').pluck(:key, :label).to_h

      object.client_attributes&.select { |k, _| k.start_with?('cde.custom_assessment') }&.transform_keys do |k|
        key = k.sub('cde.custom_assessment.', '')
        lookup.fetch(key, k)
      end
    end

  end
end
