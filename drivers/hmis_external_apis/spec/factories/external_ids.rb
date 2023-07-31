FactoryBot.define do
  factory :external_id, class: 'HmisExternalApis::ExternalId' do
    sequence(:value) do |n|
      n + 123_450
    end

    trait :mci do
      association :remote_credential, factory: :ac_hmis_mci_credential
    end

    trait :mci_unique do
      association :remote_credential, factory: :ac_hmis_mci_unique_id_credential
    end

    trait :ac_warehouse do
      association :remote_credential, factory: :ac_hmis_warehouse_credential
    end

    factory :mci_external_id, traits: [:mci]

    factory :mci_unique_id_external_id, traits: [:mci_unique]

    factory :ac_warehouse_external_id, traits: [:ac_warehouse]

    after(:build) do |external_id|
      external_id.namespace ||= external_id.remote_credential.slug
    end
  end
end
