###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::AssessmentEligibility < Types::BaseObject
    # object is Hmis::Form::Definition
    field :id, ID, null: false
    field :title, String, null: false
    field :form_definition_id, ID, null: false
    field :role, Types::Forms::Enums::AssessmentRole, null: false

    def form_definition_id
      object.id
    end
  end
end
