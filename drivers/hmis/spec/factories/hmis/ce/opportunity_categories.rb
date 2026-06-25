###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_opportunity_category, class: 'Hmis::Ce::OpportunityCategory' do
    sequence(:name) { |n| "Opportunity Category #{n}" }
  end
end
