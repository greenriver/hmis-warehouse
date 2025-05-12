###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeAssessment < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    description 'HUD Coordinated Entry Assessment'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :assessment_location, String, null: false
    field :assessment_type, HmisSchema::Enums::Hud::AssessmentType, null: true
    field :assessment_level, HmisSchema::Enums::Hud::AssessmentLevel, null: true
    field :prioritization_status, HmisSchema::Enums::Hud::PrioritizationStatus, null: true
    field :client, HmisSchema::Client, null: false
    field :form_definition_id, ID, null: true, description: 'Form Definition that was most recently used to create/update this record'

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def form_definition_id
      load_ar_association(object, :form_processor)&.definition_id
    end
  end
end
