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
    attr_accessor :logger, :notifier_config, :import, :range, :data_source, :loader_log

    # Prepare a loader for HmisCsvTwentyTwenty CSVs
    # in the directory `file_path`
    # and attribute the data to data_source_id a GrdaWarehouse::DataSource#id.
    #
    # debug: no longer used
    # remove_files: The directory will be removed after calling #load!
    # deidentified: Passed to HmisCsvTwentyTwenty::Importer::Importer when #import! is called
    def initialize(
      data_source_id:,
      file_path: File.join('tmp', 'hmis_import'),
      logger: Rails.logger,
      debug: true,
      remove_files: true,
      deidentified: false
    )
      raise ArgumentError, 'file_path must be a directory containing HMIS csv data' unless File.directory?(file_path)

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
        return complete_load(status: :failed, err: 'Unable to find a valid Export.csv') unless export_file_valid?

        load_source_files!
        complete_load(status: :loaded)
      rescue StandardError => e
        complete_load(status: :failed, err: e)
      ensure
        remove_import_files if @remove_files
      end
    end

    def import!
      # run the load step if we havent yet
      load! unless @loader_log.status.to_s.in? ['failed', 'loaded']


      return unless @loader_log.successfully_loaded?

      # puts summary_as_log_str(@loader_log.summary)

      @importer = HmisCsvTwentyTwenty::Importer::Importer.new(
        loader_id: @loader_log.id,
        data_source_id: data_source.id,
        logger: @logger,
        debug: @debug,
        deidentified: @deidentified,
      )

      res = @importer.import!
      # puts summary_as_log_str(importer_log.summary)

      res
    end

    def importer_log
      @importer&.importer_log
    end

    private def load_export_file
      begin
        @export ||= importable_files['Export.csv'].load_from_csv(
          file_path: @file_path,
          data_source_id: data_source.id,
        )
      rescue Errno::ENOENT
        log('No valid Export.csv file found')
      end
      return unless @export&.valid?

      @export
    end

    private def header_valid?(line, klass)
      return false unless line.present?

      incoming_headers = line&.map(&:to_s)
      return false unless incoming_headers.count(&:blank?).zero?

      incoming_headers = line&.map(&:to_s)&.map(&:downcase)&.map(&:to_sym)
      hud_headers = klass.hud_csv_headers.map(&:downcase)
      hud_headers.sort == incoming_headers.sort
    end

    private def header_invalid?(headers, klass)
      ! header_valid?(headers, klass)
    end

    private def export_id_addition
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

    private def expand(file_path:)
      Rails.logger.info "Expanding #{file_path}"
      Zip::File.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          Rails.logger.info entry.name
          entry.extract([@local_path, File.basename(entry.name)].join('/'))
        end
      end
      FileUtils.rm(file_path)
    end

    private def encoding_detector
      @encoding_detector ||= CharlockHolmes::EncodingDetector.new
    end

    private def load_source_files!
      @loader_log.update(status: :loading)

      importable_files.each do |file_name, klass|
        source_file_path = File.join(@file_path, file_name)
        next unless File.file?(source_file_path)

        encoding = AutoEncodingCsv.detect_encoding(source_file_path)
        File.open(source_file_path, 'r', encoding: encoding) do |file|

          if bad_line_endings?(file)
            copy_length = file.stat.size - 2
            begin
              logger.debug "Correcting bad line ending in #{source_file_path}"
              tmp_file = ::Tempfile.new(file_name)
              File.copy_stream(file, tmp_file, copy_length, 0)
              tmp_file.write("\n")
              File.open(tmp_file.path, 'r', encoding: encoding) do |tmp_file_io|
                load_source_file_pg(read_from: tmp_file_io, klass: klass, original_file_path: source_file_path)
              end
            ensure
              tmp_file.close
              tmp_file.unlink
            end
          else
            load_source_file_pg(read_from: file, klass: klass, original_file_path: source_file_path)
          end
        end
      end
    end

    private def bad_line_endings?(file)
      return false if file.stat.size < 10

      position = file.pos
      file.seek(file.stat.size - 2)
      final_characters = file.read == "\r\n"
      file.seek(position)
      final_characters
    end

    private def load_source_file_pg(read_from:, klass:, original_file_path:)
      raise 'data_source.id must be set' unless data_source.id.present?
      raise '@loader_log.id must be set' unless @loader_log.id.present?
      raise '@loaded_at must be set' unless @loaded_at.present?

      file_name = original_file_path
      base_name = File.basename(file_name)

      logger.debug do
        "Loading #{base_name} into #{klass.table_name} #{hash_as_log_str(loader_id: @loader_log.id)}"
      end

      meta_data_names = ['data_source_id', 'loader_id', 'loaded_at']
      meta_data = [data_source.id, @loader_log.id, @loaded_at.iso8601]

      header_row = CSV.parse_line(
        read_from,
        liberal_parsing: true,
        strip: true
      )
      # we are transforming the incoming CSV
      # to have only the columns we expect
      # in a known order
      mapping_status, col_mapping = *clean_header_row(header_row, klass, file_name)

      if mapping_status == :ok
        pg_cols = col_mapping + meta_data_names
      elsif mapping_status == :mapped
        extra_cols = header_row - header_row.values_at(*col_mapping.values)
        pg_cols = col_mapping.keys + meta_data_names
      else
        return # cannot continue clean_header_row logged its reason
      end

      col_list = pg_cols.map { |c| klass.connection.quote_column_name c }.join(',')
      expect_col_count = pg_cols.size
      copy_sql = <<~SQL.strip
        COPY #{klass.quoted_table_name} (#{col_list})
        FROM STDIN
        WITH (FORMAT csv,HEADER,QUOTE '"',DELIMITER ',', NULL '')
      SQL

      lines_loaded = nil
      total_lines = nil
      row_errors = []
      # SLOW_CHECK; klass.connection.transaction do
      bm = Benchmark.measure do
        pg_conn = klass.connection.raw_connection
        pg_result = pg_conn.copy_data copy_sql do
          read_from.rewind
          begin
            parser = CSV.new(
              read_from,
              headers: false,
              liberal_parsing: true,
              skip_blanks: true
            )
            parser.each do |row|
              values = if mapping_status == :mapped
                row.values_at(*col_mapping.values)
              else
                row
              end
              values += (parser.lineno == 1 ? meta_data_names : meta_data)

              # There were excess columns, probably due to an unquoted comma
              if values.size > expect_col_count
                row_errors << {
                  file_name: base_name,
                  message: 'Too many columns found',
                  details: "Line number: #{parser.lineno}",
                  source: row.to_csv,
                }
              elsif values.size < expect_col_count
                row_errors << {
                  file_name: base_name,
                  message: 'Too few columns found',
                  details: "Line number: #{parser.lineno}",
                  source: row.to_csv,
                }
              else
                csv_data = values.to_csv
                pg_conn.put_copy_data csv_data
              end
            end
          ensure
            # Remove header from count
            total_lines = parser.lineno - 1
            parser&.close
          end
          # SLOW_CHECK; data = copy_cols.zip(row + meta_data).to_h
          # SLOW_CHECK;  klass.create! data
        end
        if row_errors.any?
          @loader_log.load_errors.import(row_errors)
          row_errors.group_by { |e| e[:message] }.each do |message, errors|
            log("#{base_name}: #{message} on #{errors.count} lines")
          end
          @loader_log.summary[base_name]['total_errors'] += row_errors.size
        end
        lines_loaded = pg_result.cmd_tuples
      end
      # SLOW_CHECK; end

      @loader_log.summary[base_name].tap do |stat|
        stat['total_lines'] = total_lines
        stat['secs'] = bm.real.round(3)
        stat['cpu'] = "#{(bm.total * 100 / bm.real).round}%"
        if lines_loaded.positive?
          stat['lines_loaded'] = lines_loaded
          stat['rps'] = (lines_loaded / bm.real).round
        end
        logger.debug do
          # line_loaded comes from pg directly, if we dont trust it we can go back for a count
          # if lines_loaded > 1
          #   scope = klass.where(data_source_id: data_source.id, loader_id: @loader_log.id)
          #   scope = scope.with_deleted if klass.respond_to?(:with_deleted)
          #   stat['verified'] = scope.count
          # end
          " Loaded #{base_name} #{hash_as_log_str({ loader_id: @loader_log.id }.merge(stat))}"
        end
      end
    rescue PG::Error => e
      add_error(file_path: original_file_path, message: e.message, line: lines_loaded)
    end

    # Deal with incoming CSV that:
    # - has extra columns,
    # - is in the wrong order
    # - uses different capitalization
    # returns a mapping from the expected name
    # to the column index (zero-based) in the source
    #
    # ```ruby
    # status, mapping = clean_header_row(source_csv_headers, ....)
    # db_columns = mapping.keys
    # CVS.foreach(...) do |row|
    #   db_values = row.values_at(*db_columns.values)
    #   ...
    # end
    # ```
    private def clean_header_row(source_headers, klass, file_path)
      if source_headers.none?
        add_error(file_path: file_path, message: 'No header row found', line: 1)
        return [:missing]
      end

      valid_headers = source_headers.map(&HEADER_NORMALIZER) == klass.hud_csv_headers.map(&HEADER_NORMALIZER)

      return [:ok, klass.hud_csv_headers.map(&:to_s)] if valid_headers

      mapping = {}
      missing_cols = []
      klass.hud_csv_headers(version: '2020').each do |expected_col|
        if (col_idx = source_headers.find_index{|csv_col| expected_col.to_s.downcase.strip == csv_col.to_s.downcase.strip})
          mapping[expected_col.to_s] = col_idx
        else
          missing_cols << expected_col
        end
      end
      if missing_cols.present?
        add_error(file_path: file_path, message: "Header row missing expected columns: #{missing_cols.join ','}", line: 1)
        return [:missing_col, mapping]
      end
      #puts "#{file_path} #{mapping.inspect}"
      add_error(file_path: file_path, message: "Header row incorrect, used mapping: #{mapping.inspect}", line: 1)
      return [:mapped, mapping]
    end
    HEADER_NORMALIZER = ->(s) { s.to_s.downcase}

    # Headers need to match our style
    private def old_clean_header_row(source_headers, klass, file_path)
      if source_headers.none?
        add_error(file_path: file_path, message: 'No header row found', line: 1)
        return
      end

      if header_invalid?(source_headers, klass)
        expected_headers = klass.hud_csv_headers.map(&:to_s)
        unexpected_headers = source_headers - expected_headers
        add_error(file_path: file_path, message: "Found unexpected header columns: \n#{unexpected_headers.join(',')}; \nExpected: \n#{klass.hud_csv_headers.map(&:to_s).join(',')}", line: 1)
      end

      indexed_headers = klass.hud_csv_headers.map do |k|
        [k.to_s.downcase, k]
      end.to_h

      source_headers.map do |k|
        indexed_headers[k&.downcase].to_s
      end + ['data_source_id', 'loader_id', 'loaded_at']
    end

    def importable_files
      self.class.importable_files
    end

    private def remove_import_files
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.directory?(@file_path)
    end

    private def build_loader_log(data_source:)
      HmisCsvTwentyTwenty::Loader::LoaderLog.create!(
        data_source_id: data_source.id,
        started_at: Time.current,
        status: :started,
      )
    end

    private def export_file_valid?
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

    private def log_ids
      { data_source_id: data_source.id, loader_id: @loader_log.id }
    end

    private def start_load
      @loaded_at = Time.current
      log("Starting load for #{hash_as_log_str log_ids}.")
    end

    private def complete_load(status:, err: nil)
      elapsed = Time.current - @loaded_at
      @loader_log.update(
        completed_at: Time.current,
        status: status,
      )
      status = "#{status} error:#{err}" if err
      # log("Completed loading in #{elapsed_time(elapsed)} #{hash_as_log_str log_ids}. status:#{status}", summary_as_log_str(loader_log.summary))
      log("Completed loading in #{elapsed_time(elapsed)} #{hash_as_log_str log_ids}. status:#{status} #{summary_as_log_str(loader_log.summary)}")
    end

    private def setup_summary(file)
      @loader_log.summary ||= {}
      @loader_log.summary[file] ||= {
        'total_lines' => 0,
        'lines_loaded' => 0,
        'total_errors' => 0,
      }
    end

    private def add_error(file_path:, message:, line:)
      file_name = File.basename(file_path)
      @loader_log.load_errors.create(
        file_name: file_name,
        message: "Error in #{file_name}",
        details: message,
        source: line,
      )
      log(message)
      @loader_log.summary[file_name]['total_errors'] += 1
    end
  end
end
