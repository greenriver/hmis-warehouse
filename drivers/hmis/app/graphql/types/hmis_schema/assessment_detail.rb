###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentDetail < Types::BaseObject
    description 'HUD AssessmentDetail'
    field :id, ID, null: false
    field :definition, HmisSchema::FormDefinition, null: false
    field :assessment, HmisSchema::Assessment, null: false
    field :data_collection_stage, HmisSchema::Enums::DataCollectionStage, null: true
    field :role, String, null: false
    field :status, String, null: false

    def assessment
      load_ar_association(object, :assessment)
    end

    def definition
      load_ar_association(object, :definition)
    end
  end
end
