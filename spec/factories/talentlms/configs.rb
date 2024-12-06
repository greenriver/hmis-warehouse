FactoryBot.define do
  factory :talent_config, class: 'Talentlms::Config' do
    subdomain { 'test' }
    api_key { '1234' }
  end
end
