###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_disability, class: 'GrdaWarehouse::Hud::Disability' do
    sequence(:DisabilitiesID, 5)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
  end
end
