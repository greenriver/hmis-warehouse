###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_restricted_record, class: 'Hmis::RestrictedRecord' do
    data_source { restrictable.data_source }
    created_by { association :hmis_user, data_source: data_source }
    restrictable { association :hmis_hud_client, data_source: data_source }
  end
end
