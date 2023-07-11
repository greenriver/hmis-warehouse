###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO
# config = GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::Import.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::Import', user: User.system_user, import_hour: 6, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: 'Expand financial data zip and push back to S3')
#
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::TransactionImport.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::TransactionImport', user: User.system_user, import_hour: 7, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: 'Financial transaction data')
#
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::ClientImport.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::ClientImport', user: User.system_user, import_hour: 7, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: 'Client information for financial transactions')
#
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::ProviderImport.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::ProviderImport', user: User.system_user, import_hour: 7, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: 'Provider information for financial transations')
#
# # Ensure the bucket exists
# config.s3.create_bucket(bucket: "financial-bucket")

# # Put the zip file into s3
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::Import')
# config.s3.store(content: File.read('drivers/financial/spec/fixtures/initial_import.zip'), name: "development/combined/#{Time.current.to_s(:number)}-initial_import.zip")
#
# # Run the various importers
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::Import'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::ClientImport'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::ProviderImport'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::TransactionImport'); config.import!
#
# # Store the second import file and re-run imports
# config.s3.store(content: File.read('drivers/financial/spec/fixtures/second_import.zip'), name: "development/combined/#{Time.current.to_s(:number)}-second_import.zip")
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::Import'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::ClientImport'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::ProviderImport'); config.import!
# config = GrdaWarehouse::CustomImports::Config.find_by(import_type: 'Financial::TransactionImport'); config.import!

# This needs some additional setup before it is a full rspec test, but should successfully import the 3 csv files and leave you with 4 "financial clients"

require 'rails_helper'

RSpec.describe Financial::Import, type: :model do
  let!(:data_source) { create :grda_warehouse_data_source, id: 2 }
  let(:bucket) { "financial-bucket-#{SecureRandom.hex}" }

  around(:each) do |each|
    create_bucket(bucket)
    each.run
    delete_bucket(bucket)
  end

  it 'imports run without erroring' do
    import_config = { Financial::Import => 'Expand financial data zip and push back to S3' }
    config = GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{import_config.keys.first.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: bucket, active: true, import_type: import_config.keys.first.name, user: User.system_user, import_hour: 6, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: import_config.values.first)
    config.s3.store(content: File.read('drivers/financial/spec/fixtures/initial_import.zip'), name: "#{Rails.env}/combined/#{Time.current.to_s(:number)}-initial_import.zip")
    importers = {
      Financial::TransactionImport => 'Financial transaction data',
      Financial::ClientImport => 'Client information for financial transactions',
      Financial::ProviderImport => 'Provider information for financial transations',
    }
    importers.each do |klass, description|
      GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{klass.import_prefix}", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: bucket, active: true, import_type: klass.name, user: User.system_user, import_hour: 7, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key', description: description)
    end

    import_config.merge(importers).each_key do |klass|
      c = GrdaWarehouse::CustomImports::Config.find_by(import_type: klass.name)
      c.import!
    end
    expect(Financial::Client.count).to eq(1)
    expect(Financial::Transaction.count).to eq(1)
    expect(Financial::Provider.count).to eq(1)

    # Run a second import
    config.s3.store(content: File.read('drivers/financial/spec/fixtures/second_import.zip'), name: "#{Rails.env}/combined/#{Time.current.to_s(:number)}-second_import.zip")
    import_config.merge(importers).each_key do |klass|
      c = GrdaWarehouse::CustomImports::Config.find_by(import_type: klass.name)
      c.import!
    end
    expect(Financial::Client.count).to eq(4)
    expect(Financial::Transaction.count).to eq(4)
    expect(Financial::Provider.count).to eq(1)
  end
end
