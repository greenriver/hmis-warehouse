###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_group_viewable_entity, class: 'GrdaWarehouse::GroupViewableEntity' do
    access_group { association :access_group }
    collection { association :collection }
    entity { association :hud_project }
  end
end
