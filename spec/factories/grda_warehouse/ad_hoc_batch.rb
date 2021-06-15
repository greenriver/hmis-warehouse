require 'docker_fs_fix'

FactoryBot.define do
  factory :ad_hoc_batch_valid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }
    file do
      DockerFsFix.upload Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv'), 'text/plain'
      )
    end
  end
  factory :ad_hoc_batch_invalid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }
    file do
      DockerFsFix.upload Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/ad_hoc_batches/invalid_batch.csv'), 'text/plain'
      )
    end
  end
end
