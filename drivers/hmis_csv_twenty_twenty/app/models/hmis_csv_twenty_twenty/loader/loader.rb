###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'zip'
require 'csv'
require 'charlock_holmes'

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; HmisCsvTwentyTwenty::Loader::Loader.new(data_source_id: 90, debug: true, remove_files: false).load!

module HmisCsvTwentyTwenty::Loader
  class Loader
    include TsqlImport
    include NotifierConfig
    include HmisTwentyTwenty
    # The HMIS spec limits the field to 50 characters
    EXPORT_ID_FIELD_WIDTH = 50

    attr_accessor :logger, :notifier_config, :import, :range, :data_source

    def initialize(
      file_path: File.join('tmp', 'hmis_import'),
      data_source_id:,
      logger: Rails.logger,
      debug: true,
      remove_files: true
    )
      setup_notifier('HMIS CSV Loader 2020')
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @file_path = file_path
      @logger = logger
      @debug = debug
      @remove_files = remove_files
      @loader_log = loader_log(data_source: data_source)
      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
    end

    def self.module_scope
      'HmisCsvTwentyTwenty::Loader'
    end

    def load!
      @loaded_at = Time.current
      begin
        ensure_file_naming
        @export = load_export_file
        return unless export_file_valid?

        load_source_files!
        complete_load(status: :loaded)
      # rescue StandardError
      #   complete_load(status: :failed)
      ensure
        remove_import_files if @remove_files
      end
    end

    def load_export_file
      begin
        @export ||= export_source.load_from_csv(
          file_path: @file_path,
          data_source_id: data_source.id,
        )
      rescue Errno::ENOENT
        log('No valid Export.csv file found')
      end
      return unless @export&.valid?

      @export
    end

    def header_valid?(line, klass)
      return false unless line.present?

      incoming_headers = line&.map(&:to_s)
      return false unless incoming_headers.count(&:blank?).zero?

      incoming_headers = line&.map(&:to_s)&.map(&:downcase)&.map(&:to_sym)
      hud_headers = klass.hud_csv_headers.map(&:downcase)
      (hud_headers & incoming_headers).count == hud_headers.count
    end

    def header_invalid?(headers, klass)
      ! header_valid?(headers, klass)
    end

    def export_id_addition
      @export_id_addition ||= @range.start.strftime('%Y%m%d')
    end

    # make sure we have an ExportID in every file that
    # reflects the start date of the export
    # NOTE: The white-listing process seems to add extra commas to the CSV
    # These can break the useful export_id, so we need to remove any
    # from the existing row before tacking on the new value
    # def set_useful_export_id(row:, export_id:)
    #   # Make sure there i enough room to append the underscore and suffix
    #   truncated = row['ExportID'].chomp(', ')[0, EXPORT_ID_FIELD_WIDTH - export_id.length - 1]
    #   row['ExportID'] = "#{truncated}_#{export_id}"
    #   row
    # end

    def open_csv_file(file_path)
      file = File.read(file_path)
      # Look at the file to see if we can determine the encoding
      file_encoding = CharlockHolmes::EncodingDetector.
        detect(file).
        try(:[], :encoding)
      file_lines = IO.readlines(file_path).size - 1
      @loader_log.summary[File.basename(file_path)]['total_lines'] = file_lines
      log("Loading #{file_lines} lines in: #{file_path}")
      File.open(file_path, "r:#{file_encoding}:utf-8")
    end

    def expand(file_path:)
      Rails.logger.info "Expanding #{file_path}"
      Zip::File.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          Rails.logger.info entry.name
          entry.extract([@local_path, File.basename(entry.name)].join('/'))
        end
      end
      FileUtils.rm(file_path)
    end

    def load_source_files!
      @loader_log.update(status: :loading)
      importable_files.each do |file_name, klass|
        source_file_path = File.join(@file_path, data_source.id.to_s, file_name)
        next unless File.file?(source_file_path)

        file = open_csv_file(source_file_path)
        load_source_file(read_from: file, klass: klass)
      end
    end

    def load_source_file(read_from:, klass:)
      file_name = File.basename(read_from.path)
      csv = CSV.new(read_from, headers: false, liberal_parsing: true)
      # read the first row so we can set the headers
      headers = csv.first
      csv.rewind

      if headers.blank?
        msg = "Unable to import #{file_name}, no data"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      end

      if header_invalid?(headers, klass)
        msg = "Unable to import #{file_name}, header invalid: \n#{headers}; \nexpected a subset of: \n#{klass.hud_csv_headers.map(&:to_s)}"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      end

      # we need to accept different cased headers, but we need our
      # case for import, so we'll fix that up here and use ours going forward
      csv_headers = clean_header_row(headers, klass)

      # Strip internal newlines
      # add data_source_id
      # add loader_id
      csv = CSV.new(read_from, headers: csv_headers, liberal_parsing: true)

      headers = csv_headers + ['data_source_id', 'loader_id', 'loaded_at']
      batch = []
      begin
        csv.drop(1).each do |row|
          row.each { |k, v| row[k] = v&.gsub(/[\r\n]+/, ' ')&.strip }
          if row.count == csv_headers.count
            batch << row.fields + [data_source.id, @loader_log.id, @loaded_at]
            if batch.count == 2_000
              klass.import(headers, batch)
              loaded_lines(file_name, batch.count)
              batch = []
            end
          else
            msg = 'Line length is incorrect, unable to import:'
            add_error(file_path: read_from.path, message: msg, line: row.to_s)
          end
        end
        if batch.present?
          klass.import(headers, batch) # ensure we get the last batch
          loaded_lines(file_name, batch.count)
        end
      rescue ActiveModel::MissingAttributeError
      rescue Errno::ENOENT
        # FIXME
      end

      # NOTE: move to importing
      # # note date columns for cleanup
      # date_columns = klass.date_columns
      # # Reopen the file with corrected headers
      # csv = CSV.new(read_from, headers: header, liberal_parsing: true)
      # # since we're providing headers, skip the header row
      # csv.drop(1).each do |row|
      #   # remove any internal newlines
      #   row.each { |k, v| row[k] = v&.gsub(/[\r\n]+/, ' ')&.strip }
      #   row = klass.clean_row_for_import(row, deidentified: @deidentified)

      #   date_columns.each do |col|
      #     next if row[col].blank? || correct_date_format?(row[col])

      #     row[col] = fix_date_format(row[col])
      #   end
      # if row.count == header.count
      #   row = set_useful_export_id(row: row, export_id: export_id_addition)
      #   write_to << row
      # else
      #   msg = 'Line length is incorrect, unable to import:'
      #   add_error(file_path: read_from.path, message: msg, line: row.to_s)
      # end
      # rescue Exception => e
      #   message = "Failed while processing #{read_from.path}, #{e.message}:"
      #   add_error(file_path: read_from.path, message: message, line: row.to_s)
      # end
    end

    # NOTE: move to processing
    # # We sometimes see very odd dates, this will attempt to make them sane.
    # # Since most dates should be not too far in the future, we'll check for anything less
    # # Than a year out
    # private def fix_date_format(string)
    #   return unless string
    #   # Ruby handles yyyy-m-d just fine, so we'll allow that even though it doesn't match the spec
    #   return string if /\d{4}-\d{1,2}-\d{1,2}/.match?(string)

    #   # Sometimes dates come in mm-dd-yyyy and Ruby Date really doesn't like that.
    #   if /\d{1,2}-\d{1,2}-\d{4}/.match?(string)
    #     month, day, year = string.split('-')
    #     return "#{year}-#{month}-#{day}"
    #   end
    #   # NOTE: by default ruby converts 2 digit years between 00 and 68 by adding 2000, 69-99 by adding 1900.
    #   # https://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
    #   # Since we're almost always dealing with dates that are in the past
    #   # If the year is between 00 and next year, we'll add 2000,
    #   # otherwise, we'll add 1900
    #   @next_year ||= Date.current.next_year.strftime('%y').to_i
    #   d = Date.parse(string, false) # false to not guess at century
    #   if d.year <= @next_year
    #     d = d.next_year(2000)
    #   else
    #     d = d.next_year(1900)
    #   end
    #   d.strftime('%Y-%m-%d')
    # end

    # private def correct_date_format?(string)
    #   accepted_date_pattern.match?(string)
    # end

    # private def accepted_date_pattern
    #   @accepted_date_pattern ||= /\d{4}-\d{2}-\d{2}/.freeze
    # end

    # Headers need to match our style
    def clean_header_row(source_headers, klass)
      indexed_headers = klass.hud_csv_headers.map do |k|
        [k.to_s.downcase, k]
      end.to_h
      source_headers.map do |k|
        indexed_headers[k&.downcase].to_s
      end
    end

    def importable_files
      self.class.importable_files
    end

    def self.export_source
      importable_files['Export.csv']
    end

    def export_source
      self.class.export_source
    end

    def remove_import_files
      Rails.logger.info "Removing #{import_file_path}"
      FileUtils.rm_rf(import_file_path) if File.exist?(import_file_path)
    end

    def import_file_path
      @import_file_path ||= File.join(@file_path, data_source.id.to_s)
    end

    def loader_log(data_source:)
      HmisCsvTwentyTwenty::Loader::LoaderLog.create(
        data_source_id: data_source.id,
        started_at: Time.current,
        status: :started,
      )
    end

    def export_file_valid?
      if @export.blank?
        log('Exiting, failed to find a valid Export record')
        return false
      end
      source_id = @export[:SourceID]
      return true if data_source.source_id.blank? || data_source.source_id.casecmp(source_id).zero?

      # Construct a valid file_path for add_error
      file_path = File.join(@file_path, data_source.id.to_s, 'Export.csv')
      msg = "SourceID '#{source_id}' from Export.csv does not match '#{data_source.source_id}' specified in the data source"

      add_error(file_path: file_path, message: msg, line: '')

      @loader_log.summary['Export.csv']['total_lines'] = 1
      complete_load(status: :failed)
      false
    end

    private def correct_file_names
      @correct_file_names ||= importable_files.keys.map { |m| [m.downcase, m] }
    end

    private def ensure_file_naming
      file_path = "#{@file_path}/#{data_source.id}"
      Dir.each_child(file_path) do |filename|
        correct_file_name = correct_file_names.detect { |f, _| f == filename.downcase }&.last
        next unless correct_file_name.present? && correct_file_name != filename

        # Ruby complains if the files only differ by case, so we'll move it twice
        tmp_name = "tmp_#{filename}"
        FileUtils.mv(File.join(file_path, filename), File.join(file_path, tmp_name))
        FileUtils.mv(File.join(file_path, tmp_name), File.join(file_path, correct_file_name))
      end
    end

    def complete_load(status:)
      @loader_log.update(completed_at: Time.current, status: status)
    end

    def loaded_lines(file, count)
      @loader_log.summary[file]['lines_loaded'] += count
    end

    def setup_summary(file)
      @loader_log.summary ||= {}
      @loader_log.summary[file] ||= {
        'total_lines' => -1,
        'lines_loaded' => 0,
        'total_errors' => 0,
      }
    end

    def log(message)
      # Slack really doesn't like it when you send too many message in a row
      sleep(1)
      begin
        @notifier&.ping message
      rescue Slack::Notifier::APIError
        sleep(3)
        logger.error 'Failed to send slack'
      end
      logger.info message if @debug
    end

    def add_error(file_path:, message:, line:)
      file = File.basename(file_path)
      @loader_log.load_errors.create(
        file_name: file,
        message: "Error in #{file}",
        details: message,
        source: line,
      )
      @loader_log.summary[file]['total_errors'] += 1
      log(message)
    end
  end
end
