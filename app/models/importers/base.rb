# Current production locations
# NECHV - /mnt/hmis/nechv
# BPHC - /mnt/hmis/bphc
# DND - /mnt/hmis/dnd
# MA - /mnt/hmis/ma
# 
# Staging & Development should use GrdaWarehouse::Tasks::DumpHmisSubset to generate 
# fake data from production. Import locations for staging and development are within 
# the local tmp directory
require 'zip'
require 'csv'
require 'charlock_holmes'
require 'newrelic_rpm'
# require 'temping'

module Importers
  class Base
    include TsqlImport
    EXTRACT_DIRECTORY = 'tmp/grda_hud_zip'

    attr_accessor :directory, :source_type, :logger

    def initialize( 
        data_source_id=nil, 
        data_sources=GrdaWarehouse::DataSource.importable_via_samba,
        logger: Rails.logger,
        directory: nil   # for importing a set of plain CSV files, should be a map from data source ids to directories
      )
      if @directory = directory
        @source_type  = :directory
      end
      @logger = logger
      @refresh_type = 'Delta refresh'
      @batch_size = 10000

      # by default we import *all* data sources that are importable via samba
      @data_source_id = data_source_id.to_i if data_source_id.present?
      @data_sources   = data_sources

      @rm_files = false
    end

    def run!
      if @data_source_id.present?
        @data_sources = @data_sources.where(id: @data_source_id)
      end
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
          # Keep track of changed projects for this data source
          @changed_projects = []
          copy_files_to_tmp(smb_source: source_type, directory_source: d.source_type, data_source: d)
          
          # Load the newest updated date from the last time we ran this import
          # This is used to speed import (anything with a created date that is
          # newer is simply imported, the rest are issued as upserts)
          # @start_date = d.newest_updated_at || calculate_newest_updated_at(d)

          load()
          # Update service history for any projects that have changed
          update_service_history()

          @import.completed_at = Time.now
          @import.save

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

    private def calculate_newest_updated_at(data_source)
      logger.info "Calculating most-recent updated date"
      @import.files.to_h.keys.map do |k|
        next if k.include?('Export')
        table = k.constantize
        at = table.arel_table
        most_recent = k.constantize.where(
            data_source_id: data_source.id
          ).order( at[:DateUpdated].desc ).first
        if most_recent.present?
          most_recent.DateUpdated
        end
      end.compact.max
    end

    # more or less a munging of fetch_over_samba, though note the file deletion step -- this is to keep
    # leftover files from one source directory from polluting the next data source
    private def fetch_from_directory data_source
      dir = directory[data_source.id]
      logger.info "Copying files to temporary location..."
      FileUtils.mkdir_p extract_path unless File.exists?(extract_path)
      FileUtils.cp_r("#{dir}/.", extract_path)
      logger.info "... done Copying files"
      files = []
      Dir["#{extract_path}/*"].each do |f|
        entry = OpenStruct.new({name: File.basename(f)})
        files << [model_for_filename(entry.name).name, extract_path(entry)] if f.include?('.csv')
      end
      logger.info "Found #{files.count} files"
      @import.files = files
    end

    # copy files from SMB location to local extract directory (equivalent of unzip)
    private def fetch_over_samba data_source
      attempts = 1 # samba can be finnicky and sometimes needs a few seconds to wake up, we'll give it five attempts with 2 * attempts seconds between
      while attempts < 5 
        @import.zip = "/#{data_source.file_path.split('/').last}"
        source_path = data_source.file_path
        temporary_path = extract_path.gsub(@import.zip, '/')
        logger.info "Copying files to temporary location... #{source_path} to #{temporary_path}"
        FileUtils.cp_r(source_path, temporary_path)
        logger.info "... done Copying files"
        files = []
        Dir["#{extract_path}/*"].each do |f|
          entry = OpenStruct.new({name: File.basename(f)})
          files << [model_for_filename(entry.name).name, extract_path(entry)] if f.include?('.csv')
        end
        if files.size > 0
          break
        end
        logger.warn "Retrying #{data_source.file_path}, might need to wait for samba, sleeping for #{attempts * 2} seconds"
        sleep(attempts * 2)
        attempts += 1
      end
      logger.info "Found #{files.count} files"
      @import.files = files
    end

    # loop over each entry in unzipped_files, attempt to load them into tables with the
    # same names as the files.
    # Every record should be appended with the import_id column (id of @import)
    private def load
      return unless @import.files.present?
      files = @import.files.to_h
      # Always import the export table first since we have foreign keys
      # Also, sometimes the Export file has an extra column (HashStatus), which we need to remove
      import(klass: GrdaWarehouse::Hud::Export, file_path: files["GrdaWarehouse::Hud::Export"])
      files.delete("GrdaWarehouse::Hud::Export")
      files.each do |klass, file_path|
        # logger.info "Before load: #{klass}"
        # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
        GC.start
        klass.constantize.transaction do
          import(klass: klass.constantize, file_path: file_path)
        end
      end
      @rm_files = true
    end

    private def extract_path entry=nil
      if entry.present?
        "#{EXTRACT_DIRECTORY}#{@import.zip}/#{entry.name}"
      else
        "#{EXTRACT_DIRECTORY}#{@import.zip}"
      end
    end

    private def model_for_filename file_name
      return unless file_name.present?
      GrdaWarehouse::Hud.hud_filename_to_model(file_name)
    end

    private def import klass:, file_path:
      @klass = klass
      @file_path = file_path
      # reset some things
      reset_for_klass()
      file = read_csv_file()
      
      # get clean csv data for the file, @new_data is an array of arrays
      # the first line is the headers for the file
      @new_data = load_from_csv(file: file)
      # logger.info "After file load: #{@file_path}"
      # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      GC.start
      if ! @new_data.empty?
        # The Export.csv file always needs to be imported first.
        # If we are looking at the Export.csv file, treat if differently.
        # There should only ever by one row of data in the Export.csv file.
        if @file_path.include?('Export.csv')
          update_export()
        else
          if @refresh_type == 'Full refresh'
            # Remove any rows from the database that we don't have in our new data
            # match on hud_key, export_id and data_source_id
            remove_no_longer_needed()
          end
          # Don't bother getting any if we don't have any
          if @klass.with_deleted.exists?(data_source_id: @import.data_source.id)
            logger.info "Loading existing: #{@klass}"
            # Load all existing data, even from other export_ids.
            # We'll update the export_id if we see the same piece of data again.
            load_existing()
            # logger.info "After database load: #{@klass}"
            # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
            GC.start
          end
          if @existing.empty? && @previously_deleted.empty?
            # If we don't have any existing records, just import everything
            # ignore headers
            @to_add = @new_data
          else
            # logger.info "Before Comparing: #{@klass}"
            # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
            # We have some previous data, figure out what's changed:
            # Check to see if we already have this record,
            # if we don't (even deleted), add it
            # if we do, and the updated date is newer or we've previously deleted it
            #   update it, 
            # if the update date is older, ignore it
            @new_data.each do |row|
              h_key = row[@hud_key]
              # logger.info "Looking at: #{h_key} #{@klass}"
              # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
              # puts "#{h_key} comparing row: #{row[:DateUpdated]} exist: #{@existing[h_key].present?} prev: #{@previously_deleted[h_key].present?}"
              # puts row.inspect
              if seen_before(h_key: h_key)
                if newly_updated(h_key: h_key, row: row) || @previously_deleted[h_key].present?
                  @to_update << row
                  if @project
                    @changed_projects << row
                  end
                elsif export_id_changed(h_key: h_key, row: row)
                  @to_update << row
                end
              else
                @to_add << row
              end
            end
          end
          logger.info "Adding #{@to_add.size} records for #{@file_path}"
          process_add_queue()
          logger.info "Updating #{@to_update.size} records for #{@file_path}"
          process_update_queue()
          logger.info "Done adding & updating for #{@file_path}"
        end
      end
    end


    private def remove_files
      # If the file was extracted successfully, delete the source file
      # FIXME: this isn't working, so using rm_f so it fails gracefully.  Need a better permissions scheme
      FileUtils.rm_f(@import.zip) if @import.zip.present? && File.exist?(@import.zip)
      return unless @import.files.present?
      logger.info "Deleting: #{@import.files.to_h.values.join(', ')}"
      @import.files.to_h.values.each{|m| File.delete("#{Rails.root}/#{m}")}
    end

    private def process_add_queue
      @to_add.each do |a|
        if @import.summary[@file_path][:lines_added] % @batch_size == 0 && @import.summary[@file_path][:lines_added] > 0
          logger.info "Added #{@import.summary[@file_path][:lines_added]} lines"
        end
        begin
          a[:data_source_id] = @import.data_source.id
          @klass.import(a.keys, [a.values])
          @import.summary[@file_path][:lines_added] += 1
        rescue Exception => e
          @import.import_errors[File.basename(@file_path)] ||= []
          @import.import_errors[File.basename(@file_path)] << {
             text: "Error in #{File.basename(@file_path)}",
             message: e.message,
             line: a.inspect,
          }
          puts "Error on line #{$.} of #{File.basename(@file_path)} #{e.message} #{e.backtrace.select{|m| m.include?('hud_zip.rb')}.join(' ')}"
          @import.summary[@file_path][:total_errors] += 1
          next
        end
      end
      @to_add = []
    end

    private def process_update_queue
      @to_update.each do |a|
        if @import.summary[@file_path][:lines_updated] % (@batch_size/10) == 0 && @import.summary[@file_path][:lines_updated] > 0
          logger.info "Updated #{@import.summary[@file_path][:lines_updated]} lines"
        end
        begin
          # Update the item and ressurect it if we previously deleted it
          u = @klass.with_deleted.where(data_source_id: @import.data_source.id, @hud_key => a[@hud_key]).first
          u.update(a)
          @import.summary[@file_path][:lines_updated] += 1
        rescue Exception => e
          @import.import_errors[File.basename(@file_path)] ||= []
          @import.import_errors[File.basename(@file_path)] << {
             text: "Error in #{File.basename(@file_path)}",
             message: e.message,
             line: a.inspect,
          }
          puts "Error on line #{$.} of #{File.basename(@file_path)} #{e.message} #{e.backtrace.select{|m| m.include?('hud_zip.rb')}.join(' ')}}"
          @import.summary[@file_path][:total_errors] += 1
          next
        end
      end
      @to_update = []
    end

    private def update_service_history
      return unless @changed_projects.any?
      logger.info "Updating Service Histories for #{@changed_projects.size} projects"
      @changed_projects.each do |project|
        GrdaWarehouse::ServiceHistory.where(data_source_id: @import.data_source.id, project_id: project['ProjectID']).update_all(project_name: project['ProjectName'], organization_id: project['OrganizationID'], project_type: project['ProjectType'], project_tracking_method: project['TrackingMethod'])
      end
      logger.info "Done updating Service Histories"
    end

    # Fetch existing items in the same export_id
    # compare to the incoming file
    # soft-delete any from the database we no longer have
    def remove_no_longer_needed
      logger.info "Determining what to delete for #{@klass}"
      existing = @klass.where(data_source_id: @import.data_source.id, ExportID: @export_id)
        .pluck(@hud_key, :id).to_h
      hud_keys_to_delete = existing.keys - @new_data.map{|row| row[@hud_key]}
      ids_to_delete = existing.select{|k,v| hud_keys_to_delete.include?(k)}.values
      ids_to_delete.each_slice(@batch_size) do |batch|
        @klass.where(ExportID: @export_id, data_source_id: @import.data_source.id, id: batch).update_all(@klass.hud_paranoid_column => Time.now)
      end
      logger.info "Deleted #{ids_to_delete.size} #{@klass}"

    end

    def setup_import data_source:
      @import = GrdaWarehouse::ImportLog.new
      @import.created_at = Time.now
      @import.data_source = data_source
      @import.summary = {}
      @import.import_errors = {}
    end

    def copy_files_to_tmp smb_source:, directory_source:, data_source:
      # Look for a mounted samba share, these won't be zipped, so we just copy them
      case smb_source || directory_source
      when :directory
        fetch_from_directory(data_source)
        raise "no directory provided for #{d.name}" unless directory.key?(data_source.id)
        logger.info "Importing #{data_source.name} from #{directory[data_source.id]}"
      when 'samba'
        fetch_over_samba(data_source)
        logger.info "Importing #{data_source.name} from #{data_source.file_path}"
      end   
    end

    def load_from_csv file:
      @new_data = []
      logger.info "Loading #{@file_path} in to RAM"
      file.each_line do |line|
        @import.summary[@file_path][:total_lines] += 1
        if $. == 1 
          @header_commas = line.count(',')
        else
          @line_commas = line.count(',')
          # Sometimes we have a return within the row.  We'll do some really simple
          # cleanup to try and grab the next line and append it to avoid most errors
          if @line_commas > 0 && @line_commas < @header_commas
            file.seek(+1, IO::SEEK_CUR)
            line += file.readline
          end
        end
        begin
          CSV.parse(line) do |row|
            if @header_row
              @header_row = false
              gather_file_metadata(row)
              next
            else
              if row.size == @headers.size
                @new_data << @headers.zip(row).to_h.with_indifferent_access
              else
                @import.import_errors[File.basename(@file_path)] ||= []
                @import.import_errors[File.basename(@file_path)] << {
                   text: "Error on line #{$.} of #{File.basename(@file_path)}",
                   message: 'Incorrect number of columns',
                   line: line,
                }
                puts @import.import_errors[File.basename(@file_path)].last.except(:line).values.join(' ')
                @import.summary[@file_path][:total_errors] += 1
              end
            end
          end # CSV.parse
        rescue CSV::MalformedCSVError => e
          @import.import_errors[File.basename(@file_path)] ||= []
          @import.import_errors[File.basename(@file_path)] << {
             text: "Error on line #{$.} of #{File.basename(@file_path)}",
             message: e.message,
             line: line,
          }
          puts "Error on line #{$.} of #{File.basename(@file_path)} #{e.message} #{e.backtrace.select{|m| m.include?('hud_zip.rb')}.join(' ')}"
          @import.summary[@file_path][:total_errors] += 1
          next
        end # begin
      end # file.each_line
      @new_data
    end


    def gather_file_metadata(row)
      @headers = row
      # figure out the locations of DateCreated, DateUpdate, DateDeleted
      # this is way faster than array#zip every time
      @date_created_index = @headers.index('DateCreated')
      @date_updated_index = @headers.index('DateUpdated')
      @date_deleted_index = @headers.index('DateDeleted')
      @export_id_index = @headers.index('ExportID')
      @hud_key = @headers.first
    end

    def update_export
      raise "Incorrect row count in #{@file_path}, should be 1, found #{@new_data.size}" if @new_data.size > 1
      row = @new_data.first
      e = @klass.where(
        @hud_key => row[@hud_key],
        data_source_id: @import.data_source.id
      ).first_or_create
      e.update!(row)
      # Set Refresh Type
      @refresh_type = ::HUD.export_directive(row['ExportDirective'].to_i)
      @export_id = row['ExportID']
      @import.summary[@file_path][:lines_added] += 1
    end

    def reset_for_klass
      @header_row = true
      @rows = []
      @headers = []
      @date_created_index = ''
      @date_updated_index = ''
      @date_deleted_index = ''
      @export_id_index = ''
      @to_add = []
      @to_update = []
      @existing = {}
      @previously_deleted = {}
      @project = @file_path.include?('Project.csv')
      @hud_key = nil
    end

    def read_csv_file
      # Look at the file to see if we can determine the encoding
      @file_encoding = CharlockHolmes::EncodingDetector
        .detect(File.read(@file_path))
        .try(:[], :encoding)
      file_lines = IO.readlines(@file_path).size - 1
      logger.info "Processing #{file_lines} lines in: #{@file_path}"

      @import.summary[@file_path] = {
        total_lines: -1, 
        lines_added: 0, 
        lines_updated: 0, 
        total_errors: 0
      }
      File.open(@file_path, "r:#{@file_encoding}:utf-8")
    end

    def seen_before h_key:
      @existing[h_key].present? || @previously_deleted[h_key].present?
    end

    def newly_updated h_key:, row:
      @existing[h_key].present? && @existing[h_key][:DateUpdated].to_time < row[:DateUpdated].try(:to_time)
    end

    def export_id_changed h_key:, row:
      existing = @existing[h_key]
      existing.present? && existing[:DateUpdated].to_time == row[:DateUpdated].try(:to_time) && existing[:ExportID] != row[:ExportID]
    end

    # Shove all of the existing records into a temporary table in
    # postgres to avoid using a ton of ram, but to keep
    # the import performant
    def load_existing
      klass_headers = [@headers.first, :DateUpdated, :id]
      @existing = {}
      @new_data.each_slice(@batch_size) do |batch|
        @klass
          .where(data_source_id: @import.data_source.id, @headers.first => batch.map{|m| m[@headers.first]})
          .pluck(*klass_headers, :ExportID)
          .each do |m|
            @existing[m.first] = (klass_headers + [:ExportID]).zip(m).to_h.with_indifferent_access
        end
      end
      @previously_deleted = {}
      @new_data.each_slice(@batch_size) do |batch|
        @klass.only_deleted
          .where(data_source_id: @import.data_source.id, @headers.first => batch.map{|m| m[@headers.first]})
          .pluck(*klass_headers)
          .each do |m| 
            @previously_deleted[m.first] = klass_headers.zip(m).to_h.with_indifferent_access
        end
      end
      logger.info "Found #{@existing.size} existing #{@klass} and #{@previously_deleted.size} previously deleted"
    end
  end
end
