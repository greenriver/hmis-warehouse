# Current locations
# NECHV - /mnt/hmis/nechv
# BPHC - /mnt/hmis/bphc
# DND - /mnt/hmis/dnd
# MA - /mnt/hmis/ma
require 'zip'
require 'csv'
require 'charlock_holmes'
require 'faker'
require 'newrelic_rpm'
require 'fileutils'
# require 'temping'
# Work around a faker bug: https://github.com/stympy/faker/issues/278
I18n.reload!

module Importers
  class UploadedZip < Base
    def initialize(upload_id:, rm_files: false, logger: Rails.logger)
      raise 'Upload Required' unless upload_id.present?
      @logger = logger
      @refresh_type = 'Delta refresh'
      @batch_size = 10000
      @upload = GrdaWarehouse::Upload.find(upload_id)
      @data_source_id = @upload.data_source.id
      @data_sources = GrdaWarehouse::DataSource.where(id: @data_source_id)
      # Process the oldest upload file for this datasource
      
      @rm_files = rm_files
    end

    def run!
      return unless @upload.present?
      logger.info "Looking at #{@data_sources.count} data sources"
      @data_sources.each do |d|
        # Provide Application locking so we can be sure we aren't already importing this data source
        if GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{d.id}")
          logger.warn "Import of Data Source: #{d.short_name} already running...exiting"
          next
        end
        # Add MSSQL support to https://github.com/mceachen/with_advisory_lock see local gem
        GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{d.id}") do
          setup_import(data_source: d)
          @import.zip = "#{d.manual_import_path}"
          unzip()
          
          # Keep track of changed projects for this data source
          @changed_projects = []
          load_file_locations()

          # Load the newest updated date from the last time we ran this import
          # This is used to speed import (anything with a created date that is
          # newer is simply imported, the rest are issued as upserts)
          # @start_date = d.newest_updated_at || calculate_newest_updated_at(d)
          load()
          # Update service history for any projects that have changed
          update_service_history()
          
          @import.completed_at = Time.now
          @import.save

          @upload.update(percent_complete: 100, completed_at: @import.completed_at)

          # You can't trust the End Date from the Export table, so go fetch the most recent updated_date from the various tables
          d.newest_updated_at = calculate_newest_updated_at(d)

          d.last_imported_at = Time.now
          d.save
          if @rm_files
            remove_files
          end
        end
      end
    end

    def unzip
      reconstitute_path = @upload.file.current_path
      puts "Re-constituting upload file to: #{reconstitute_path}"
      FileUtils.mkdir_p(File.dirname(reconstitute_path)) unless File.directory?(File.dirname(reconstitute_path))
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(@upload.content)
      end
      return unless File.exist?(@upload.file.current_path)
      begin
        unzipped_files = []
        @logger.info "Unzipping #{@upload.file.current_path}"
        Zip::File.open(@upload.file.current_path) do |zip_file|
          zip_file.each do |entry|
            file_name = entry.name.split('/').last
            next unless file_name.include?('.csv')
            @logger.info "Extracting #{file_name}"
            unzip_path = "#{extract_path}/#{file_name}"
            @logger.info "To: #{unzip_path}"
            unzip_parent = File.dirname(unzip_path)
            FileUtils.mkdir_p(unzip_parent) unless File.directory?(unzip_parent)
            entry.extract(unzip_path)
            unzipped_files << [GrdaWarehouse::Hud.hud_filename_to_model(file_name).name, unzip_path] if file_name.include?('.csv')
          end
        end
      rescue StandardError => ex
        Rails.logger.error ex.message
        raise "Unable to extract file: #{@upload.file.current_path}"
      end
      # If the file was extracted successfully, delete the source file,
      # we have a copy in the database
      File.delete(@upload.file.current_path) if File.exist?(@upload.file.current_path)
      # archive_path = File.dirname(@upload.file.current_path.sub(Rails.root.to_s + '/tmp/', "var/upload_archive/#{Date.today.strftime("%Y-%m-%d")}/"))
      # FileUtils.mkdir_p(archive_path) unless File.directory?(archive_path)
      # FileUtils.mv(@upload.file.current_path, archive_path) if File.exist?(@upload.file.current_path)
      @upload.update({percent_complete: 0.01, unzipped_files: unzipped_files, import_errors: []})
      @upload.save!
    end

    # We've already placed the files appropriately, just make note of that
    def load_file_locations 
      files = []
      @logger.info "Looking in #{extract_path}/* for files..."
      Dir["#{extract_path}/*"].each do |f|
        entry = OpenStruct.new({name: File.basename(f)})
        files << [model_for_filename(entry.name).name, extract_path(entry)] if f.include?('.csv')
      end
      logger.info "Found #{files.count} files"
      @import.files = files    
    end
  end
end
