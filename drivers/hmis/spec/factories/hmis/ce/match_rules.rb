FactoryBot.define do
  factory :hmis_ce_match_rule, class: 'Hmis::Ce::Match::Rule' do
    sequence(:name) { |n| "Rule #{n}" }
    applicability_config { {} }
  end
end
