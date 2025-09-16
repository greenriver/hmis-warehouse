# frozen_string_literal: true

FactoryBot.define do
  factory :ad_hoc_batch_valid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }

    after(:build) do |batch|
      file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv')
      uploaded_file = Rack::Test::UploadedFile.new(file_path, 'text/csv')
      batch.batch_file.attach(
        io: uploaded_file,
        filename: 'initial_batch.csv',
        content_type: 'text/csv',
      )
    end
  end

  factory :ad_hoc_batch_invalid, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch' }

    after(:build) do |batch|
      file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/invalid_batch.csv')
      uploaded_file = Rack::Test::UploadedFile.new(file_path, 'text/csv')
      batch.batch_file.attach(
        io: uploaded_file,
        filename: 'invalid_batch.csv',
        content_type: 'text/csv',
      )
    end
  end

  factory :ad_hoc_batch_valid_excel, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch Excel' }

    after(:build) do |batch|
      file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.xlsx')
      uploaded_file = Rack::Test::UploadedFile.new(
        file_path,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
      batch.batch_file.attach(
        io: uploaded_file,
        filename: 'initial_batch.xlsx',
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
    end
  end

  factory :ad_hoc_batch_invalid_excel, class: 'GrdaWarehouse::AdHocBatch' do
    description { 'Ad-Hoc Batch Invalid Excel' }

    after(:build) do |batch|
      file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/invalid_batch.xlsx')
      uploaded_file = Rack::Test::UploadedFile.new(
        file_path,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
      batch.batch_file.attach(
        io: uploaded_file,
        filename: 'invalid_batch.xlsx',
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
    end
  end
end
