FactoryBot.define do
  factory :external_id, class: 'HmisExternalApis::ExternalId' do
    sequence(:value) do |n|
      (n + 123_450).to_s
    end

    trait :mci do
      association :remote_credential, factory: :ac_hmis_mci_credential
    end

    trait :mci_unique do
      association :remote_credential, factory: :ac_hmis_warehouse_credential
      namespace { HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE }
    end

    factory :mci_external_id, traits: [:mci]

    factory :mci_unique_id_external_id, traits: [:mci_unique]

    after(:build) do |external_id|
      external_id.namespace ||= external_id.remote_credential.slug
    end
  end
end
