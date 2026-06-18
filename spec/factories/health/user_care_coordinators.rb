###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :user_care_coordinator, class: 'Health::UserCareCoordinator' do
    association :user, factory: :user
    association :coordination_team, factory: :coordination_team
  end
end
