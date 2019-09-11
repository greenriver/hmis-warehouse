FactoryBot.define do
  factory :hud_assessment_question, class: 'GrdaWarehouse::Hud::AssessmentQuestion' do
    sequence(:AssessmentQuestionID, 15)
    sequence(:AssessmentID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    sequence(:AssessmentQuestionGroup)
    sequence(:AssessmentQuestionOrder)
    AssessmentQuestion { 'Question' }
    AssessmentAnswer { 'Answer' }
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
