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
