# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::Import.import_prefix}/", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::Import', user: User.system_user, import_hour: 6, s3_access_key_id: 'local_access_key', s3_secret_access_key: 'local_secret_key')
# config.s3.create_bucket(bucket: "financial-bucket")
# config.s3.store(content: File.read('drivers/financial/spec/fixtures/initial_import.zip'), name: "#{Rails.env}/#{Financial::Import.import_prefix}/initial_import.zip")
