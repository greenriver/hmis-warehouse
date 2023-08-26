FactoryBot.define do
  factory :internal_system, class: 'HmisExternalApis::InternalSystem' do
    sequence(:name) do |n|
      len = HmisExternalApis::InternalSystem::NAMES.length
      HmisExternalApis::InternalSystem::NAMES[n % len]
    end

    HmisExternalApis::InternalSystem::NAMES.each do |the_name|
      trait the_name.downcase.to_sym do
        name { the_name }
      end
    end
    # Added to deal with non-unique db errors coming up
    initialize_with do
      HmisExternalApis::InternalSystem.find_or_create_by(name: name)
    end
  end
end
