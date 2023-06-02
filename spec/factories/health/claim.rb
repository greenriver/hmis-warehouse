FactoryBot.define do
  factory :health_claim, class: 'Health::Claim' do
    max_date { Date.current }
  end
end
