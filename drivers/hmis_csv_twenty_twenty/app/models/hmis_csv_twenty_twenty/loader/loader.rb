###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
    include ActionView::Helpers::DateHelper
    # The HMIS spec limits the field to 50 characters
    EXPORT_ID_FIELD_WIDTH = 50
    SELECT_BATCH_SIZE = 10_000
    INSERT_BATCH_SIZE = 5_000

    attr_accessor :logger, :notifier_config, :import, :range, :data_source, :loader_log

    def initialize( # rubocop:disable Metrics/ParameterLists
      data_source_id:,
      file_path: File.join('tmp', 'hmis_import'),
      logger: Rails.logger,
      debug: true,
      remove_files: true,
      deidentified: false
    )
      setup_notifier('HMIS CSV Loader 2020')
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @file_path = file_path
      @logger = logger
      @debug = debug
      @remove_files = remove_files
      @deidentified = deidentified
      @loader_log = build_loader_log(data_source: data_source)
      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
    end

    def self.module_scope
      'HmisCsvTwentyTwenty::Loader'
    end

    def load!
      start_load
      begin
        ensure_file_naming
        @export = load_export_file
        export_valid = export_file_valid?
        return unless export_valid

        load_source_files! if export_valid
        complete_load(status: :loaded)
      rescue StandardError
        complete_load(status: :failed)
      ensure
        remove_import_files if @remove_files
      end
    end

    def import!
      return unless @loader_log.successfully_loaded?

      @importer = HmisCsvTwentyTwenty::Importer::Importer.new(
        loader_id: @loader_log.id,
        data_source_id: data_source.id,
        logger: @logger,
        debug: @debug,
        deidentified: @deidentified,
      )

      @importer.import!
    end

    def importer_log
      @importer&.importer_log
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
      hud_headers.sort == incoming_headers.sort
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
        source_file_path = File.join(@file_path, file_name)
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
        err = 'No data.'
        msg = "Unable to import #{file_name}: #{err}"
        log(msg)
        add_error(file_path: read_from.path, message: err, line: '')
        return
      end

      if header_invalid?(headers, klass)
        err = "Header invalid: \n#{headers}; \nexpected a subset of: \n#{klass.hud_csv_headers.map(&:to_s)}"
        msg = "Unable to import #{file_name}, #{err}"
        log(msg)
        add_error(file_path: read_from.path, message: err, line: '')
        return
      end

      # we need to accept different cased headers, but we need our
      # case for import, so we'll fix that up here and use ours going forward
      csv_headers = clean_header_row(headers, klass)

      # Strip internal newlines
      # add data_source_id
      # add loader_id
      csv = CSV.new(read_from, headers: csv_headers, liberal_parsing: true, empty_value: nil, skip_blanks: true)

      headers = csv_headers + ['data_source_id', 'loader_id', 'loaded_at']
      batch = []
      begin
        csv.drop(1).each do |row|
          row.each do |k, v|
            row[k] = v&.gsub(/[\r\n]+/, ' ')&.strip.presence
          end
          if row.count == csv_headers.count
            batch << row.fields + [data_source.id, @loader_log.id, @loaded_at]
            if batch.count == INSERT_BATCH_SIZE
              klass.import(headers, batch)
              loaded_lines(file_name, batch.count)
              batch = []
            end
          else
            msg = "Line length is incorrect: #{row.count}"
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
    end

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
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.exist?(@file_path)
    end

    def build_loader_log(data_source:)
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
      return true if data_source.source_id.blank? || data_source.source_id.casecmp(source_id)&.zero?

      # Construct a valid file_path for add_error
      file_path = File.join(@file_path, 'Export.csv')
      msg = "SourceID '#{source_id}' from Export.csv does not match '#{data_source.source_id}' specified in the data source"
      log(msg)
      add_error(file_path: file_path, message: msg, line: '')

      @loader_log.summary['Export.csv']['total_lines'] = 1
      complete_load(status: :failed)
      false
    end

    private def correct_file_names
      @correct_file_names ||= importable_files.keys.map { |m| [m.downcase, m] }
    end

    private def ensure_file_naming
      file_path = @file_path
      Dir.each_child(file_path) do |filename|
        correct_file_name = correct_file_names.detect { |f, _| f == filename.downcase }&.last
        next unless correct_file_name.present? && correct_file_name != filename

        # Ruby complains if the files only differ by case, so we'll move it twice
        tmp_name = "tmp_#{filename}"
        FileUtils.mv(File.join(file_path, filename), File.join(file_path, tmp_name))
        FileUtils.mv(File.join(file_path, tmp_name), File.join(file_path, correct_file_name))
      end
    end

    def start_load
      @loaded_at = Time.current
      log("Starting HMIS CSV Data Load for data source: #{data_source.id} loader log: #{@loader_log.id}")
    end

    def complete_load(status:)
      elapsed = Time.current - @loaded_at
      @loader_log.update(completed_at: Time.current, status: status)
      log("Completed HMIS CSV Data Load for data source: #{data_source.id} in #{distance_of_time_in_words(elapsed)}")
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
      @notifier&.ping message
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
