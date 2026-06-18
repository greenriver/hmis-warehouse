###
# Copyright Green River Data Group, Inc.
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
