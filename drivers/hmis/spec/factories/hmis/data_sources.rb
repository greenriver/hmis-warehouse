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

  factory :authenticated_hmis_data_source, parent: :hmis_data_source do
    hmis { GraphqlHelpers::HMIS_HOSTNAME }
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
