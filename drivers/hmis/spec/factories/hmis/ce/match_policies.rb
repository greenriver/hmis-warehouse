###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_policy, class: 'Hmis::Ce::Match::Policy' do
    sequence(:name) { |n| "Resource Policy #{n}" }
  end
end
