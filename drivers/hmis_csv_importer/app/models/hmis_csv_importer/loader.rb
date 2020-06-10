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
module HmisCsvImporter
  class Loader
    # The HMIS spec limits the field to 50 characters
    EXPORT_ID_FIELD_WIDTH = 50

    def load_export_file
      begin
        @export ||= export_source.load_from_csv(
          file_path: @file_path,
          data_source_id: @data_source.id,
        )
      rescue Errno::ENOENT
        log('No valid Export.csv file found')
      end
      return unless @export&.valid?

      @export
    end

    def header_valid?(line, klass)
      incoming_headers = line&.map(&:downcase)&.map(&:to_sym)
      hud_headers = klass.hud_csv_headers.map(&:downcase)
      (hud_headers & incoming_headers).count == hud_headers.count
    end

    def short_line?(line, comma_count)
      CSV.parse_line(line).count < comma_count
    rescue StandardError
      line.count(',') < comma_count
    end

    def long_line?(line, comma_count)
      CSV.parse_line(line).count > (comma_count + 1)
    rescue StandardError
      line.count(',') > comma_count
    end

    def export_id_addition
      @export_id_addition ||= @range.start.strftime('%Y%m%d')
    end

    # make sure we have an ExportID in every file that
    # reflects the start date of the export
    # NOTE: The white-listing process seems to add extra commas to the CSV
    # These can break the useful export_id, so we need to remove any
    # from the existing row before tacking on the new value
    def set_useful_export_id(row:, export_id:)
      # Make sure there i enough room to append the underscore and suffix
      truncated = row['ExportID'].chomp(', ')[0, EXPORT_ID_FIELD_WIDTH - export_id.length - 1]
      row['ExportID'] = "#{truncated}_#{export_id}"
      row
    end

    def open_csv_file(file_path)
      file = File.read(file_path)
      # Look at the file to see if we can determine the encoding
      file_encoding = CharlockHolmes::EncodingDetector.
        detect(file).
        try(:[], :encoding)
      file_lines = IO.readlines(file_path).size - 1
      setup_summary(File.basename(file_path))
      @import.summary[File.basename(file_path)][:total_lines] = file_lines
      log("Processing #{file_lines} lines in: #{file_path}")
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

    def clean_source_files
      importable_files.each do |file_name, klass|
        source_file_path = File.join(@file_path, @data_source.id.to_s, file_name)
        next unless File.file?(source_file_path)

        destination_file_path = "#{source_file_path}_updating"
        file = open_csv_file(source_file_path)
        clean_source_file(destination_path: destination_file_path, read_from: file, klass: klass)
        @import.files << [klass.name, file_name]
        if File.exist?(destination_file_path)
          FileUtils.mv(destination_file_path, source_file_path)
        elsif File.exist?(source_file_path)
          # We failed at cleaning the import file, delete the source
          # So we don't accidentally import an unclean file
          File.delete(source_file_path)
        end
      end
    end

    def clean_source_file(destination_path:, read_from:, klass:)
      csv = CSV.new(read_from, headers: true, liberal_parsing: true)
      # read the first row so we can set the headers
      headers = csv.headers
      csv.rewind # go back to the start for processing

      if headers.blank?
        msg = "Unable to import #{File.basename(read_from.path)}, no data"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      elsif header_valid?(headers, klass)
        # we need to accept different cased headers, but we need our
        # case for import, so we'll fix that up here and use ours going forward
        header = clean_header_row(headers, klass)
        write_to = CSV.open(
          destination_path,
          'wb',
          headers: header,
          write_headers: true,
          force_quotes: true,
        )
      else
        msg = "Unable to import #{File.basename(read_from.path)}, header invalid: #{headers}; expected a subset of: #{klass.hud_csv_headers}"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      end
      # note date columns for cleanup
      date_columns = klass.date_columns
      # Reopen the file with corrected headers
      csv = CSV.new(read_from, headers: header, liberal_parsing: true)
      # since we're providing headers, skip the header row
      csv.drop(1).each do |row|
        # remove any internal newlines
        row.each { |k, v| row[k] = v&.gsub(/[\r\n]+/, ' ')&.strip }
        row = klass.clean_row_for_import(row, deidentified: @deidentified)

        date_columns.each do |col|
          next if row[col].blank? || correct_date_format?(row[col])

          row[col] = fix_date_format(row[col])
        end
        if row.count == header.count
          row = set_useful_export_id(row: row, export_id: export_id_addition)
          write_to << row
        else
          msg = 'Line length is incorrect, unable to import:'
          add_error(file_path: read_from.path, message: msg, line: row.to_s)
        end
      rescue Exception => e
        message = "Failed while processing #{read_from.path}, #{e.message}:"
        add_error(file_path: read_from.path, message: message, line: row.to_s)
      end
      write_to.close
    end

    # We sometimes see very odd dates, this will attempt to make them sane.
    # Since most dates should be not too far in the future, we'll check for anything less
    # Than a year out
    private def fix_date_format(string)
      return unless string
      # Ruby handles yyyy-m-d just fine, so we'll allow that even though it doesn't match the spec
      return string if /\d{4}-\d{1,2}-\d{1,2}/.match?(string)

      # Sometimes dates come in mm-dd-yyyy and Ruby Date really doesn't like that.
      if /\d{1,2}-\d{1,2}-\d{4}/.match?(string)
        month, day, year = string.split('-')
        return "#{year}-#{month}-#{day}"
      end
      # NOTE: by default ruby converts 2 digit years between 00 and 68 by adding 2000, 69-99 by adding 1900.
      # https://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
      # Since we're almost always dealing with dates that are in the past
      # If the year is between 00 and next year, we'll add 2000,
      # otherwise, we'll add 1900
      @next_year ||= Date.current.next_year.strftime('%y').to_i
      d = Date.parse(string, false) # false to not guess at century
      if d.year <= @next_year
        d = d.next_year(2000)
      else
        d = d.next_year(1900)
      end
      d.strftime('%Y-%m-%d')
    end

    private def correct_date_format?(string)
      accepted_date_pattern.match?(string)
    end

    private def accepted_date_pattern
      @accepted_date_pattern ||= /\d{4}-\d{2}-\d{2}/.freeze
    end

    # Headers need to match our style
    def clean_header_row(source_headers, klass)
      indexed_headers = klass.hud_csv_headers.map do |k|
        [k.to_s.downcase, k]
      end.to_h
      source_headers.map do |k|
        indexed_headers[k.downcase].to_s
      end
    end

    def self.export_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Export
    end

    def export_source
      self.class.export_source
    end

    def export_file_valid?
      if @export.blank?
        log('Exiting, failed to find a valid export file')
        return false
      end
      if @data_source.source_id.present?
        source_id = @export[:SourceID]
        if @data_source.source_id.casecmp(source_id) != 0
          # Construct a valid file_path for add_error
          file_path = File.join(@file_path, @data_source.id.to_s, 'Export.csv')
          msg = "SourceID '#{source_id}' from Export.csv does not match '#{@data_source.source_id}' specified in the data source"

          add_error(file_path: file_path, message: msg, line: '')

          # Populate @import for error reporting
          @import.files << 'Export.csv'
          @import.summary['Export.csv'][:total_lines] = 1
          complete_load
          return false
        end
      end
      true
    end

    def remove_import_files
      import_file_path = File.join(@file_path, @data_source.id.to_s)
      Rails.logger.info "Removing #{import_file_path}"
      FileUtils.rm_rf(import_file_path) if File.exist?(import_file_path)
    end

    def complete_load
      # FIXEME
    end
  end
end
