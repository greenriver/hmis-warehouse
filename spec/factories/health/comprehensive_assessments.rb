FactoryBot.define do
  factory :cha, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { Date.current }
    # collection_method { :in_person }
  end
  factory :cha_incomplete, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { nil }
  end

  factory :health_ca, class: 'HealthComprehensiveAssessment::Assessment' do
    completed_on { Date.current }
  end

  factory :ca_assessment, class: 'Health::CaAssessment' do
  end
end
