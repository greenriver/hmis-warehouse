module Types
  class HmisSchema::AssessmentEligibility < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :assessment_id, ID, null: false
  end
end
