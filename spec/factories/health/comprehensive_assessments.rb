###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :cha, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { Date.current }
    # collection_method { :in_person }
  end
  factory :cha_incomplete, class: 'Health::ComprehensiveHealthAssessment' do
    completed_at { nil }
  end
end
