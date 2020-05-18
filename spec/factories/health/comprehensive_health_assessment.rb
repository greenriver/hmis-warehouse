FactoryBot.define do
  factory :cha, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { Date.current }
  end
  factory :cha_incomplete, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { nil }
  end
end
