###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :mci_clearance_result, class: 'HmisExternalApis::AcHmis::MciClearanceResult' do
    sequence(:mci_id) do |n|
      (n + 100_000).to_s
    end
    score { 95 }
    client { association :hmis_hud_client, strategy: :build }
    existing_client_id { nil }
  end
end
