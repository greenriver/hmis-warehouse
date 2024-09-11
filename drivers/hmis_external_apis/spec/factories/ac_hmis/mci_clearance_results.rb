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
