###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_hud_custom_case_note, class: 'Hmis::Hud::CustomCaseNote', parent: :hmis_base_factory do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:CustomCaseNoteID, 100)
    information_date { Date.current }
    date_created { Time.current }
    date_updated { Time.current }
    content { 'test note' }
  end
end
