###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :whitelisted_projects_for_client, class: 'GrdaWarehouse::WhitelistedProjectsForClients' do
    # `has_one :data_source` on this model prevents `association :data_source` from setting data_source_id.
    data_source_id { create(:grda_warehouse_data_source).id }
    sequence(:ProjectID) { |n| "P-#{n}" }
  end
end
