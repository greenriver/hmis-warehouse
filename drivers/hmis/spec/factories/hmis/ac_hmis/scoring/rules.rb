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
  end
end
