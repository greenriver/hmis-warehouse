FactoryBot.define do
  factory :hud_assessment_result, class: 'GrdaWarehouse::Hud::AssessmentResult' do
    sequence(:AssessmentResultID, 12)
    sequence(:AssessmentID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    AssessmentResultType { 'Result Type' }
    AssessmentResult { 'Result' }
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
