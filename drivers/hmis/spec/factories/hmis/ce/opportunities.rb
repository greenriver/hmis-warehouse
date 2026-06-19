###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_opportunity, class: 'Hmis::Ce::Opportunity' do
    sequence(:name) { |n| "Opportunity #{n}" }
    status { 'open' }
    unit { association :hmis_unit }
  end
end
