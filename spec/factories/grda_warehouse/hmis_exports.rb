###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_hmis_export, class: 'GrdaWarehouse::HmisExport' do
    export_id { SecureRandom.uuid }
    created_at { Time.zone.now }

    trait :with_zip do
      after(:build) do |export|
        export.hmis_zip.attach(
          io: StringIO.new('zip-data'),
          filename: 'export.zip',
          content_type: 'application/zip',
        )
      end
    end
  end
end
