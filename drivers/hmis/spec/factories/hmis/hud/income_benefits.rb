###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_income_benefit, class: 'Hmis::Hud::IncomeBenefit', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:IncomeBenefitsID, 500)
    information_date { Date.yesterday }
    data_collection_stage { 1 }
  end
end
