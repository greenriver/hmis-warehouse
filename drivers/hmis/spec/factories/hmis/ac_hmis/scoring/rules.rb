###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ac_hmis_scoring_rule, class: 'AcHmis::Scoring::Rule' do
    link_id { 'test_question' }
    form_definition_identifier { 'test_form' }
    algorithm { 'test_algorithm' }
    criteria_type { AcHmis::Scoring::Rule::VALUE }
    weight { 0.5 }
  end
end
