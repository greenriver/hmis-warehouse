###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_service, class: 'GrdaWarehouse::Hud::Service' do
    sequence(:ServicesID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
  end
end
