FactoryBot.define do
  factory :hmis_ce_client_match_policy, class: 'Hmis::Ce::ClientMatch::Policy' do
    sequence(:name) { |n| "Resource Policy #{n}" }
  end
end
