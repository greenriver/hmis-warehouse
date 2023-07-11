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
