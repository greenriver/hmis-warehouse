FactoryBot.define do
  factory :internal_system, class: 'HmisExternalApis::InternalSystem' do
    sequence(:name) do |n|
      len = HmisExternalApis::InternalSystem::NAMES.length
      HmisExternalApis::InternalSystem::NAMES[n % len]
    end
  end
end
