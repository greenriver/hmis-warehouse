###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :vt_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    association :data_source, factory: :vt_source_data_source
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
  end
end
