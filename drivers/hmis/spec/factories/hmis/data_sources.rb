###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_data_source, class: 'GrdaWarehouse::DataSource' do
    sequence(:authoritative, &:zero?)
    sequence(:hmis) { |n| "#{GraphqlHelpers::HMIS_HOSTNAME}.#{n}" }
    name { 'HMIS' }
    short_name { 'HMIS' }
    # association :client, factory: :hmis_hud_client
    source_type { :sftp }
  end

  # Data source with HMIS hostname matching the one in GraphqlHelpers.
  # This is the one that should be used in almost all of our spec tests,
  # except when we are testing multi-hmis-data-source scenarios.
  factory :hmis_primary_data_source, parent: :hmis_data_source do
    hmis { GraphqlHelpers::HMIS_HOSTNAME }

    # if data source exists with this hmis hostname, return it instead of building a new one
    initialize_with do
      GrdaWarehouse::DataSource.find_or_create_by(hmis: hmis)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
