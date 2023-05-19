FactoryBot.define do
  factory :external_id, class: 'HmisExternalApis::ExternalId' do
    sequence(:value) do |n|
      n + 123_450
    end

    trait :mci do
      association :remote_credential, factory: :ac_hmis_mci_credential
    end

    factory :mci_external_id, traits: [:mci]

    after(:build) do |external_id|
      external_id.namespace = external_id.remote_credential.slug
    end
  end
end
