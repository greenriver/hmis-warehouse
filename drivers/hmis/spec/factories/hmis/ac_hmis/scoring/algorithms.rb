###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ac_hmis_scoring_algorithm, class: 'AcHmis::Scoring::Algorithm' do
    name { 'default_algorithm' }
    namespace { 'alt_aha' }
  end
end
