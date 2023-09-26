module HmisExternalApis::ShHmis::Importers
  # importer = HmisExternalApis::ShHmis::Importers::S3Importer.new
  # importer.list_files
  # importer.select_latest_file
  # importer.fetch_and_unzip_latest_file
  # importer.run_migration!(clobber: true)
  class S3Importer
    attr_accessor :creds
    attr_accessor :s3
    attr_accessor :s3_file_substr
    attr_accessor :dir

    def initialize(s3_file_substr: nil, dir: 'var/migration/data')
      # GrdaWarehouse::RemoteCredentials::S3.create!(username: 'unknown', encrypted_password: '', bucket: <bucket name>, path: <prefix>, slug: 'hmis_migration_files', active: true)
      self.creds = GrdaWarehouse::RemoteCredentials::S3.active.find_by(slug: 'hmis_migration_files')
      self.s3 = creds.s3
      self.s3_file_substr = s3_file_substr
      self.dir = dir

      raise 'Credential not found' unless creds
    end

    def list_files
      s3.list_objects(prefix: creds.s3_prefix)
    end

    def select_latest_file
      files = s3.list_objects(prefix: creds.s3_prefix)
      key = if s3_file_substr.present?
        files.filter { |o| o.key.include?(s3_file_substr) }.first.key
      else
        files.first.key
      end
      key = key.gsub("#{creds.s3_prefix}/", '') if creds.s3_prefix.present?
      key
    end

    def fetch_and_unzip_latest_file
      file_name = select_latest_file
      FileUtils.mkdir_p(dir)
      zipfile = "#{dir}/data.zip"
      s3.fetch(file_name: file_name, prefix: creds.s3_prefix, target_path: zipfile)
      extract_zip(zipfile, dir)
    end

    def run_migration!(clobber: false, upload_log: true)
      log_file = "var/migration/#{Date.current.strftime('%Y-%m-%d')}-migration-log.txt"
      ENV['SH_HMIS_IMPORT_LOG_FILE'] = log_file

      importer = HmisExternalApis::ShHmis::Importers::CustomDataElementsImporter.new(dir: dir, clobber: clobber)
      importer.run!

      # Upload log file to S3
      s3.put(file_name: log_file, prefix: creds.s3_prefix) if upload_log
    end

    def extract_zip(file, destination)
      FileUtils.mkdir_p(destination)

      Zip::File.open(file) do |zip_file|
        zip_file.each do |f|
          fpath = File.join(destination, f.name)
          FileUtils.mkdir_p(File.dirname(fpath))
          zip_file.extract(f, fpath) unless File.exist?(fpath)
        end
      end
    end
  end
end
