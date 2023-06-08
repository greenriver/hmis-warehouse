namespace :import do
  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do # |_, args|
    # args.with_defaults(defaults)
    file_name = 'var/ac_projects/incoming/HMIS_HUD_CS_ZIP_File_2 (2).zip'
    # dir = 'var/ac_projects/incoming'
    # data_source = HmisExternalApis::AcHmis.data_source

    # importer = HmisExternalApis::AcHmis::Importers::ProjectsImporter.new(zip_file: file_name)

    c = Aws::S3::Client.new(endpoint: ENV.fetch('MINIO_ENDPOINT', 'https://s3.dev.test:9000'), region: 'us-east-1', access_key_id: 'local_access_key', secret_access_key: 'local_secret_key', force_path_style: true)
    bucket = ENV.fetch('ACTIVE_STORAGE_BUCKET', 'active-storage')
    c.create_bucket(bucket: bucket) rescue 'nil'

    key = "mper/#{SecureRandom.hex}.zip"

    c.put_object(
      {
        body: File.read(file_name, encoding: 'ascii-8bit'),
        bucket: bucket,
        key: key,
      },
    )

    HmisExternalApis::AcHmis::Importers::ProjectsImporter.import_from_s3

    # loader = HmisCsvImporter::Loader::Loader.new(data_source_id: data_source.id, remove_files: false, file_path: dir)
    # Rails.logger.info 'Expanding zip'
    # loader.send(:expand, file_path: file_name, keep_zip: true)
    # loader.load!
  end
end
