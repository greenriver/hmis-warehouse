###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_client_search_query, class: 'Hmis::ClientSearchQuery' do
    created_by factory: [:hmis_user]
    params { { 'text_search' => 'test' } }
    fingerprint { Hmis::ClientSearchQuery.generate_fingerprint(params) }

    after(:build) do |record|
      next if record.data_source_id.present?
      next unless record.created_by.is_a?(Hmis::User) && record.created_by.hmis_data_source_id.present?

      record.data_source_id = record.created_by.hmis_data_source_id
    end
  end
end
