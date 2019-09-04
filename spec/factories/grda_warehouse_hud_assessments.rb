FactoryBot.define do
  factory :hud_assessment, class: 'GrdaWarehouse::Hud::Assessment' do
    sequence(:AssessmentID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    AssessmentLocation { 'Nearby' }
    AssessmentType { 3 }
    AssessmentLevel { 2 }
    PrioritizationStatus { 1 }
    sequence(:AssessmentDate) do |n|
      dates = [
        Date.today,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n % 5].to_date
    end
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
