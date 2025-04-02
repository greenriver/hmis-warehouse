###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
    sequence(:CoCCode) { |n| "XX-#{n.to_s.rjust(3, '0')}" }
    association :data_source, factory: :source_data_source
  end
end
