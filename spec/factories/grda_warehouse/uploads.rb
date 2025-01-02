FactoryBot.define do
  factory :grda_warehouse_upload, class: 'GrdaWarehouse::Upload' do
    association :data_source, factory: :source_data_source
    association :user, factory: :user
    file { 'test data' }

    after(:build) do |upload|
      upload.hmis_zip.attach(
        io: StringIO.new('Fake ZIP file content'),
        filename: 'test_hmis.zip',
        content_type: 'application/zip',
      )
    end
  end
end
