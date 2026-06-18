###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ssm, class: 'Health::SelfSufficiencyMatrixForm' do
    completed_at { Date.current }
  end

  factory :thrive, class: 'HealthThriveAssessment::Assessment' do
    completed_on { Date.current }
  end

  factory :hrsn_screening, class: 'Health::HrsnScreening' do
  end
end
