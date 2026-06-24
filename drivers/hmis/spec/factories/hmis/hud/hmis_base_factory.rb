###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_base_factory, class: 'Hmis::Hud::Base' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Time.current }
    DateUpdated { Time.current }
  end

  trait :skip_validate do
    to_create { |instance| instance.save(validate: false) }
  end
end
