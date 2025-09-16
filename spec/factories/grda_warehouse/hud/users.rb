###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_user, class: 'GrdaWarehouse::Hud::User' do
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
