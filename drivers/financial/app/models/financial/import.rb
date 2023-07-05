###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'

# Setup notes:
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::Import.import_prefix}/", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::Import', user: User.system_user, import_hour: 6)
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::TransactionImport.import_prefix}/", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::TransactionImport', user: User.system_user, import_hour: 7)
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::ClientImport.import_prefix}/" data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::ClientImport', user: User.system_user, import_hour: 7)
# GrdaWarehouse::CustomImports::Config.create(s3_prefix: "#{Rails.env}/#{Financial::ProviderImport.import_prefix}/", data_source_id: 2, s3_region: 'us-east-1', s3_bucket: 'financial-bucket', active: true, import_type: 'Financial::ProviderImport', user: User.system_user, import_hour: 7)
module Financial
  class Import < ::GrdaWarehouse::CustomImports::ImportFile
    def self.description
      'Financial Transaction Metadata'
    end

    def self.import_prefix
      'combined'
    end

    def import!(force = false)
      return unless config.s3.present?
      return unless check_hour || force

      start_import
      fetch_and_push
      complete_import
    end

    private def expected_files
      {
        'Clients.csv' => Financial::ClientImport,
        'Providers.csv' => Financial::ProviderImport,
        'Transactions.csv' => Financial::TransactionImport,
      }.freeze
    end

    # Download the most-recent zip file from s3, unzip, shove each of the CSVs back up
    # for further processing
    def fetch_and_push
      file = most_recent_on_s3
      return unless file

      log("Found #{file}")
      Dir.mktmpdir(['tmp', File.dirname(file)]) do |tmp_dir|
        target_path = File.join(tmp_dir, File.basename(file))
        FileUtils.mkdir_p(tmp_dir)

        config.s3.fetch(
          file_name: file,
          target_path: target_path.to_s,
        )

        expected_content_types = ['application/zip']
        content_type = ::MimeMagic.by_path(target_path)
        raise "Incorrect content type #{content_type}, expected #{expected_content_types}" unless content_type.to_s.in?(expected_content_types)

        update(
          file: file,
          contents: File.read(target_path),
          content_type: content_type,
          status: 'loading',
        )

        Dir.mktmpdir(['tmp', 'extracted', File.dirname(file)]) do |extract_path|
          expand(file_path: target_path, extract_path: extract_path)
          expected_files.each do |csv_name, klass|
            local_csv_file = File.join([extract_path, csv_name])
            raise "Missing expected file #{csv_name}" unless File.exist?(local_csv_file)

            csv_config = config.class.active.find_by(import_type: klass)
            destination = "#{csv_config.s3_prefix}/#{Time.current.to_s(:db)}-#{csv_name}"
            csv_config.s3.store(content: File.read(local_csv_file), name: destination)
          end
        end
      end
    end

    private def expand(file_path:, extract_path:)
      Rails.logger.info "Expanding #{file_path}"
      ZipFile.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          Rails.logger.info entry.name
          entry.extract([extract_path, File.basename(entry.name)].join('/'))
        end
      end
    end
  end
end
