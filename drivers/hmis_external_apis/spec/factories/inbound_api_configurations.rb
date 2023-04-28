FactoryBot.define do
  factory :inbound_api_configuration, class: 'HmisExternalApis::InboundApiConfiguration' do
    internal_system
    sequence(:external_system_name) { |n| ['LINK', 'MPER', 'AABB', 'QQRR', 'AAAA'][n % 5] }
  end
end
