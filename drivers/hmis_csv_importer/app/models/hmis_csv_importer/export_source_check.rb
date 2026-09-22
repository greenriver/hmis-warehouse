###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'zip'
require 'csv'
require 'open3'

# Reads the source identity out of an uploaded HMIS CSV archive's Export.csv without
# expanding the archive, so an upload can be compared against its destination data
# source before any job is queued. See
# drivers/hmis_csv_importer/app/models/hmis_csv_importer/loader/loader.rb for the
# equivalent comparison the Loader makes once the import is underway.
module HmisCsvImporter
  class ExportSourceCheck
    EXPORT_FILE_NAME = 'export.csv'
    SEVEN_ZIP_EXTENSION = '.7z'
    # Same binary Importers::HmisAutoMigrate::UploadedZip#force_standard_zip uses
    SEVEN_ZIP_BIN = '7z'
    SEVEN_ZIP_TIMEOUT_SECONDS = 30
    # Export.csv is a header and one row; the cap stops a crafted archive from
    # streaming an unbounded member into a web request
    MAX_EXPORT_FILE_BYTES = 1_000_000
    # The Loader normalizes headers the same way, see Loader::Loader::HEADER_NORMALIZER
    HEADER_NORMALIZER = ->(s) { s.to_s.downcase }

    Result = Struct.new(:source_id, :source_name, :export_start_date, :export_end_date, :error, keyword_init: true) do
      def ok?
        error.nil?
      end

      def source_id_matches?(expected)
        return false unless ok?
        return false if expected.blank? || source_id.blank?

        expected.casecmp(source_id)&.zero? || false
      end
    end

    # @param file_path [String] path to the uploaded archive on disk
    def initialize(file_path:)
      @file_path = file_path
    end

    # @return [Result]
    def run
      contents = seven_zip? ? seven_zip_contents : zip_contents
      return contents if contents.is_a?(Result)

      parse_export(contents)
    end

    # Case-sensitive to match UploadedZip#force_standard_zip, so this check and the
    # import job always agree on which archives get unpacked with 7z
    private def seven_zip?
      File.extname(@file_path) == SEVEN_ZIP_EXTENSION
    end

    # @return [String, Result] the Export.csv contents, or a Result carrying the failure
    private def zip_contents
      contents = nil
      Zip::File.open(@file_path) do |zip|
        entry = zip.find { |e| File.basename(e.name).casecmp(EXPORT_FILE_NAME).zero? }
        return Result.new(error: :missing_export_file) if entry.nil?

        contents = entry.get_input_stream.read(MAX_EXPORT_FILE_BYTES)
      end
      contents
    rescue Zip::Error, Errno::ENOENT
      Result.new(error: :malformed_zip)
    end

    # 7z is a different container format, so rubyzip cannot read it. Shell out to
    # the same binary the import job uses rather than leaving the SourceID unknown.
    # @return [String, Result]
    private def seven_zip_contents
      entry = seven_zip_entry_name
      return entry if entry.is_a?(Result)

      contents = run_seven_zip('e', '-so', @file_path, entry)
      return Result.new(error: :unverifiable) if contents.nil?

      contents
    end

    # @return [String, Result] the archive-relative path of Export.csv
    private def seven_zip_entry_name
      listing = run_seven_zip('l', '-ba', '-slt', @file_path)
      return Result.new(error: :unverifiable) if listing.nil?

      names = listing.lines.filter_map { |line| line[/\APath = (.+?)\s*\z/, 1] }
      name = names.find { |n| File.basename(n).casecmp(EXPORT_FILE_NAME).zero? }
      return Result.new(error: :missing_export_file) if name.nil?

      name
    end

    # @return [String, nil] stdout, or nil when 7z failed, timed out, or is absent
    private def run_seven_zip(*args)
      output = nil
      Open3.popen2(SEVEN_ZIP_BIN, *args, '-p', err: File::NULL) do |stdin, stdout, wait_thread|
        stdin.close
        output = stdout.read(MAX_EXPORT_FILE_BYTES)
        # Past the cap 7z still has more to write; closing ends it now rather
        # than leaving it blocked on a full pipe until the timeout expires
        stdout.close
        unless wait_thread.join(SEVEN_ZIP_TIMEOUT_SECONDS)
          Process.kill('KILL', wait_thread.pid)
          return nil
        end
        return nil unless wait_thread.value.success?
      end
      output.to_s
    rescue Errno::ENOENT, Errno::EPIPE, Errno::ESRCH
      nil
    end

    private def parse_export(contents)
      csv = CSV.parse(contents.to_s, headers: true, header_converters: HEADER_NORMALIZER)
      row = csv.first
      return Result.new(error: :unparseable_export_file) if row.nil?

      Result.new(
        source_id: row['sourceid'],
        source_name: row['sourcename'],
        export_start_date: parse_date(row['exportstartdate']),
        export_end_date: parse_date(row['exportenddate']),
      )
    rescue CSV::MalformedCSVError, ArgumentError
      Result.new(error: :unparseable_export_file)
    end

    private def parse_date(value)
      return nil if value.blank?

      Date.parse(value)
    rescue Date::Error
      nil
    end
  end
end
