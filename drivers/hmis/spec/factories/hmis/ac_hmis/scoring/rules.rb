###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_scoring_rule, class: 'Hmis::Scoring::Rule' do
    link_id { 'test_question' }
    form_definition_identifier { 'test_form' }
    algorithm { 'test_algorithm' }
    criteria_type { Hmis::Scoring::Rule::VALUE }
    weight { 0.5 }

    # No default model_version, so every spec states which model its rules belong to
    trait :v1 do
      model_version { 1 }
    end

    trait :v2 do
      model_version { 2 }
    end
  end
end
