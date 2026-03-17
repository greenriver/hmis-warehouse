###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_client_search_query, class: 'Hmis::ClientSearchQuery' do
    created_by { association :user }
    params { { 'text_search' => 'test' } }
    fingerprint { Hmis::ClientSearchQuery.generate_fingerprint(params, created_by) }
  end
end
