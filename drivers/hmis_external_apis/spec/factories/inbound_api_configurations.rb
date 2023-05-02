FactoryBot.define do
  factory :inbound_api_configuration, class: 'HmisExternalApis::InboundApiConfiguration' do
    sequence(:internal_system_name) { |n| ['referral', 'involvement', 'somesystem', 'someothersystem'][n % 4] }
    sequence(:external_system_name) { |n| ['LINK', 'MPER', 'AABB', 'QQRR', 'AAAA'][n % 5] }
  end
end
