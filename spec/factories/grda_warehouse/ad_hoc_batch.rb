FactoryBot.define do
  factory :ad_hoc_batch_valid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv'), 'text/plain') }
    content { file.read }
  end
  factory :ad_hoc_batch_invalid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/ad_hoc_batches/invalid_batch.csv'), 'text/plain') }
    content { file.read }
  end
end
