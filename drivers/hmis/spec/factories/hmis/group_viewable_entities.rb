###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_group_viewable_entity, class: 'Hmis::GroupViewableEntity' do
    collection { association :hmis_access_group }
    entity { association :hmis_hud_project }
  end
end
