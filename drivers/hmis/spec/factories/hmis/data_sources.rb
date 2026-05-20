###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  # Builds a new HMIS data source with a unique hostname.
  factory :hmis_data_source, class: 'GrdaWarehouse::DataSource' do
    sequence(:hmis) { |n| "#{GraphqlHelpers::HMIS_HOSTNAME}.#{n}" }
    name { |n| "HMIS #{n}" }
    short_name { |n| "HMIS #{n}" }
    source_type { :samba }
    authoritative { true }
  end

  # Data source with HMIS hostname matching the one in GraphqlHelpers.
  # This is the one that should be used in almost all of our spec tests,
  # except when we are testing multi-HMIS-data-source scenarios.
  factory :hmis_primary_data_source, parent: :hmis_data_source do
    hmis { GraphqlHelpers::HMIS_HOSTNAME }
    name { 'HMIS' }
    short_name { 'HMIS' }
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
