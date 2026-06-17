###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :cohort_client, class: 'GrdaWarehouse::CohortClient' do
    adjusted_days_homeless { 111 }
    rank { 5 }
  end
end
