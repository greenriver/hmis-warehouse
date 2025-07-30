###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ac_hmis_scoring_algorithm_threshold, class: 'AcHmis::Scoring::Threshold' do
    association :algorithm, factory: :ac_hmis_scoring_algorithm
    threshold { 0.5 }
    points { 1 }
  end
end
