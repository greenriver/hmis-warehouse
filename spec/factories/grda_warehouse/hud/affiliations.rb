###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_affiliation, class: 'GrdaWarehouse::Hud::Affiliation' do
    sequence(:ProjectID, 100)
    sequence(:AffiliationID, 1)
  end
end
