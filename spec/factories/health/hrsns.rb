FactoryBot.define do
  factory :ssm, class: 'Health::SelfSufficiencyMatrixForm' do
    completed_at { Date.current }
  end

  factory :thrive, class: 'HealthThriveAssessment::Assessment' do
    completed_on { Date.current }
  end

  factory :hrsn_screening, class: 'Health::HrsnScreening' do
  end
end
