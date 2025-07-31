# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_rule, class: 'Hmis::Ce::Match::Rule' do
    sequence(:name) { |n| "Rule #{n}" }
    applicability_config { {} }
  end

  factory :hmis_ce_eligibility_requirement, parent: :hmis_ce_match_rule do
    rule_type { 'eligibility_requirement' }
    expression { 'current_age >= 18' }
  end

  factory :hmis_ce_priority_scheme, parent: :hmis_ce_match_rule do
    rule_type { 'priority_scheme' }
    expression { 'days_homeless' }
    rank { 1 }
  end
end
