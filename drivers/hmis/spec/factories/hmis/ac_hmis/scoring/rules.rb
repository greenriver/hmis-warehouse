###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ac_hmis_scoring_rule, class: 'AcHmis::Scoring::Rule' do
    association :algorithm, factory: :ac_hmis_scoring_algorithm
    link_id { 'test_question' }
    weight { 0.5 }
    exact_value { nil }
    min_value { nil }
    max_value { nil }
  end
end
