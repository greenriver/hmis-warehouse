# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_hmis_export, class: 'GrdaWarehouse::HmisExport' do
    export_id { SecureRandom.uuid }
    created_at { Time.zone.now }

    trait :with_zip do
      after(:build) do |export|
        export.content = 'zip-data'
      end
    end
  end
end
