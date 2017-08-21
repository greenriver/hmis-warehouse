# Current locations
# NECHV - /mnt/hmis/nechv
# BPHC - /mnt/hmis/bphc
# DND - /mnt/hmis/dnd
# MA - /mnt/hmis/ma
require 'zip'
require 'csv'
require 'net/sftp'
require 'charlock_holmes'
require 'faker'
require 'newrelic_rpm'
# require 'temping'
# Work around a faker bug: https://github.com/stympy/faker/issues/278
I18n.reload!

module Importers
  class Sftp < Base
    EXTRACT_DIRECTORY='tmp/hmis_sftp'

    def run!
      @config = YAML::load(ERB.new(File.read(Rails.root.join("config","hmis_sftp.yml"))).result)[Rails.env]
      logger.info "Looking at #{@data_sources.count} data sources"
      @data_sources.each do |d|
        # only deal with data sources we expect via SFTP
        next unless @config[d.short_name].present?
        # Provide Application locking so we can be sure we aren't already importing this data source
        if GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{d.id}")
          logger.warn "Import of Data Source: #{d.short_name} already running...exiting"
          next
        end
        GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{d.id}") do
          setup_import(data_source: d)
          @import.zip = "#{d.manual_import_path}"
          download_from_sftp(data_source: d)
          # Sometimes the export id is reused even when the start date is changed.
          # To help smooth this along, we'll tack on the year and date to the end
          munge_export_id()
          
          # # Keep track of changed projects for this data source
          # @changed_projects = []
          # load_file_locations()

          # # Load the newest updated date from the last time we ran this import
          # # This is used to speed import (anything with a created date that is
          # # newer is simply imported, the rest are issued as upserts)
          # # @start_date = d.newest_updated_at || calculate_newest_updated_at(d)
          # load()
          # # Update service history for any projects that have changed
          # update_service_history()
          
          # @import.completed_at = Time.now
          # @import.save

          # @upload.update(percent_complete: 100, completed_at: @import.completed_at)

          # # You can't trust the End Date from the Export table, so go fetch the most recent updated_date from the various tables
          # d.newest_updated_at = calculate_newest_updated_at(d)

          # d.last_imported_at = Time.now
          # d.save
          # if @rm_files
          #   remove_files
          # end
        end
      end
    end

    def munge_export_id
      return unless @export_id_addition.present?
      @import.files.to_h.values.each do |file|
        munged_file_path = file.sub(File.basename(file), "munged_#{File.basename(file)}")
        munged_file = File.new(munged_file_path, 'w')
        csv = CSV.new(munged_file)
        CSV.foreach(file, headers: true, return_headers: true) do |row|
          if row.header_row?
            munged_file << row
          else
            row['ExportID'] = "#{row['ExportID']}_#{@export_id_addition}"
            munged_file << row
          end
        end
      end
    end

    def download_from_sftp(data_source:)
      return unless @config[data_source.short_name].present?
      logger.info "Downloading files from SFTP for #{data_source.short_name}..."
      connection_info = @config[data_source.short_name]
      sftp = Net::SFTP.start(
        connection_info['host'], 
        connection_info['username'],
        password: connection_info['password'],
        # verbose: :debug,
        auth_methods: ['publickey','password']
      )
      path = connection_info['path']
      files = []
      sftp.dir.foreach(path) do |entry|
        files << entry.name
      end
      return if files.empty?
      # Fetch the most recent file
      file = files.max
      @export_id_addition = file.match(/(\d{6})\d{2}\./)&.captures&.first

      @import.zip = File.basename(file, '.*')
      logger.info "Found #{file}"
      destination = "#{EXTRACT_DIRECTORY}/#{data_source.short_name}"
      FileUtils.mkdir_p(destination) unless File.exists? destination
      sftp.download!("#{path}/#{file}", "#{destination}/#{file}")
      # Use atool to extract the files.  The 7zip gem is flaky
      file_path = "#{Rails.root.to_s}/#{destination}/#{file}"
      system_call = "arepack --force --extract-to=#{extract_path(data_source: data_source)} #{file_path}"
      logger.info "Asking the system to: #{system_call}"
      success = system(system_call)
      return unless success
      # Cleanup zip file if successful
      logger.info "Removing extracted file: #{file_path}"
      FileUtils.rm(file_path)
      
      files = []
      logger.info "#{extract_path(data_source: data_source)}/*"
      Dir["#{extract_path(data_source: data_source)}/*"].each do |f|
        entry = OpenStruct.new({name: File.basename(f)})
        files << [model_for_filename(entry.name).name, extract_path(data_source: data_source, entry: entry)] if f.include?('.csv')
      end
      puts files.inspect
      logger.info "Found #{files.count} files"
      @import.files = files

      # convert from 7zip to zip
      # if file.include?('.7z')
      #   logger.info "Converting #{file} from 7zip to zip"
      #   zip_file = file.sub('7z', 'zip')
      #   system_call = "arepack -rv --format=zip #{Rails.root.to_s}/#{destination}/#{file} #{Rails.root.to_s}/#{destination}/#{zip_file}"
      #   logger.info "Asking the system to: #{system_call}"
      #   success = system(system_call)
      #   puts success
      # end
    end

    def extract_path data_source:, entry: nil
      if entry.present?
        "#{EXTRACT_DIRECTORY}/#{data_source.short_name}/#{@import.zip}/#{entry.name}"
      else
        "#{EXTRACT_DIRECTORY}/#{data_source.short_name}/#{@import.zip}"
      end
    end
  end
end
