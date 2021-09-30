###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class HmisExport < GrdaWarehouseBase
    self.table_name = :exports
    attr_accessor :fake_data
    attr_accessor :recurring_hmis_export_id
    attr_accessor :user_ids
    # attr_accessor :zip_password

    mount_uploader :file, HmisExportUploader

    belongs_to :user, class_name: 'User'

    has_one :recurring_hmis_export_link
    has_one :recurring_hmis_export, through: :recurring_hmis_export_link

    scope :ordered, -> do
      order(created_at: :desc)
    end

    scope :has_content, -> do
      where.not(content_type: nil)
    end

    scope :for_list, -> do
      has_content.
      select(column_names - ['content', 'file'])
    end

    def save_zip_to(path)
      reconstitute_path = ::File.join(path, file.file.filename)
      FileUtils.mkdir_p(path) unless ::File.directory?(path)
      ::File.open(reconstitute_path, 'w+b') do |file|
        file.write(content)
      end
      reconstitute_path
    end

    # unzip the export to a path, returns directory path containing csv files
    def unzip_to path
      Rails.logger.info "Re-constituting zip file to: #{path}"
      zip_path = save_zip_to(path)
      begin
        unzipped_files = []
        extract_path = zip_path.gsub('.zip', '')
        Rails.logger.info "Unzipping #{zip_path} to #{extract_path}"
        Zip::File.open(zip_path) do |zip_file|
          zip_file.each do |entry|
            file_name = entry.name.split('/').last
            next unless file_name.include?('.csv')
            Rails.logger.info "Extracting #{file_name}"
            unzip_path = "#{extract_path}/#{file_name}"
            Rails.logger.info "To: #{extract_path}"
            unzip_parent = ::File.dirname(unzip_path)
            FileUtils.mkdir_p(unzip_parent) unless ::File.directory?(unzip_parent)
            entry.extract(unzip_path)
            unzipped_files << [GrdaWarehouse::Hud.hud_filename_to_model(file_name).name, unzip_path] if file_name.include?('.csv')
          end
        end
      rescue StandardError => ex
        Rails.logger.error ex.message
        raise "Unable to extract file: #{zip_path}: #{ex.message}"
      end
      # If the file was extracted successfully, delete the source file,
      ::File.delete(zip_path) if ::File.exist?(zip_path)
      return extract_path
    end


  end
end
