FactoryBot.define do
  factory :hmis_data_source, class: 'GrdaWarehouse::DataSource' do
    id { 1 }
    authoritative { true }
    hmis { GraphqlHelpers::HMIS_HOSTNAME }
    name { 'HMIS' }
    short_name { 'HMIS' }
    # association :client, factory: :hmis_hud_client
    source_type { :sftp }
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
