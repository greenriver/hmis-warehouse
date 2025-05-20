###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class HmisExport < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = :exports
    attr_accessor :fake_data
    attr_accessor :recurring_hmis_export_id
    attr_accessor :user_ids
    attr_accessor :enforce_project_date_scope
    # attr_accessor :zip_password

    # attachment via CarrierWave
    mount_uploader :file, HmisExportUploader

    # attachment via ActiveStorage
    has_one_attached :hmis_zip

    belongs_to :user, class_name: 'User', optional: true

    has_one :recurring_hmis_export_link
    has_one :recurring_hmis_export, through: :recurring_hmis_export_link

    scope :ordered, -> do
      order(created_at: :desc)
    end

    scope :has_content, -> do
      where.not(completed_at: nil)
    end

    scope :for_list, -> do
      has_content.
        select(column_names - ['content', 'file'])
    end

    # for file migration
    scope :unprocessed_s3_migration, -> do
      migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::HmisExport').pluck(:record_id)
      all = pluck(:id)
      unmigrated = all - migrated
      return none if unmigrated.blank?

      where(id: unmigrated)
    end

    def copy_to_s3!
      return unless content.present?
      return unless valid? # Ignore uploads that are already invalid (data source deleted?)
      return if hmis_zip.attached? # don't re-process

      puts "Migrating #{file} to S3"

      Tempfile.create(binmode: true) do |tmp_file|
        tmp_file.write(content)
        tmp_file.rewind
        hmis_zip.attach(io: tmp_file, content_type: content_type, filename: file, identify: false)
      end

      # Save no-matter validity state
      self.content = nil
      save!(validate: false)
    end
    # END for file migration

    def runtime
      return unless started_at.present? && completed_at.present?

      seconds = ((completed_at - started_at) / 1.minute).round * 60
      "Completed in #{distance_of_time_in_words(seconds)}"
    end

    def describe_filter_as_html
      keys ||= known_params
      filter.describe_filter_as_html(keys)
    end

    def known_params
      [
        # Ignore a bunch of options because we manually show them for backwards compatibility
        # :start_date,
        # :end_date,
        # :version,
        # :hash_status,
        # :period_type,
        # :directive,
        # :include_deleted,
        # :faked_pii,
        # :confidential,
        :project_ids,
        :project_group_ids,
        :organization_ids,
        :data_source_ids,
        :coc_codes,
        :enforce_project_date_scope,
      ]
    end

    def self.clean_params(params)
      # if period type is updated, deleted records are required
      params[:include_deleted] = true if params[:period_type].to_i == 1
      params
    end

    def filter
      ::Filters::HmisExport.new(options)
    end

    def source_type
      filter.source_type || 3 # data warehouse
    end

    def export_file_name
      "HMIS_export_#{created_at.to_s.gsub(/\W+/, '_')}.zip"
    end

    def save_zip_to(path)
      reconstitute_path = ::File.join(path, export_file_name)
      FileUtils.mkdir_p(path) unless ::File.directory?(path)
      ::File.open(reconstitute_path, 'w+b') do |file|
        file.write(hmis_zip.download)
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
      rescue StandardError => e
        Rails.logger.error e.message
        raise "Unable to extract file: #{zip_path}: #{e.message}"
      end
      # If the file was extracted successfully, delete the source file,
      ::File.delete(zip_path) if ::File.exist?(zip_path)
      return extract_path
    end
  end
end
