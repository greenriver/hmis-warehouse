FactoryBot.define do
  factory :ssm, class: 'Health::SelfSufficiencyMatrixForm' do
    completed_at { Date.current }
  end
end
