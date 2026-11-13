###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'zip'
require 'csv'

# Reads the source identity out of an uploaded HMIS CSV archive's Export.csv without
# expanding the archive, so an upload can be compared against its destination data
# source before any job is queued. See
# drivers/hmis_csv_importer/app/models/hmis_csv_importer/loader/loader.rb for the
# equivalent comparison the Loader makes once the import is underway.
module HmisCsvImporter
  class UploadValidityCheck
    EXPORT_FILE_NAME = 'export.csv'
    SEVEN_ZIP_EXTENSION = '.7z'
    # Export.csv is a header and one row; the cap stops a crafted archive from
    # streaming an unbounded member into a web request
    MAX_EXPORT_FILE_BYTES = 1_000_000
    # The Loader normalizes headers the same way, see Loader::Loader::HEADER_NORMALIZER
    HEADER_NORMALIZER = ->(s) { s.to_s.downcase }

    # Reasons the archive cannot be checked at all. There is nothing for a user to
    # acknowledge -- the Loader would fail on these anyway.
    HARD_REJECT_ERRORS = [:malformed_zip, :missing_export_file, :unparseable_export_file].freeze

    ERROR_MESSAGES = {
      malformed_zip: 'The uploaded file could not be read as a zip archive.',
      missing_export_file: 'The uploaded zip does not contain an Export.csv.',
      unparseable_export_file: 'The Export.csv in the uploaded zip could not be read.',
    }.freeze

    Result = Struct.new(:source_id, :source_name, :export_start_date, :export_end_date, :error, keyword_init: true) do
      def ok?
        error.nil?
      end

      def source_id_matches?(expected)
        return false unless ok?
        return false if expected.blank? || source_id.blank?

        expected.casecmp(source_id)&.zero? || false
      end

      def hard_reject?
        HARD_REJECT_ERRORS.include?(error)
      end

      # @return [String, nil] what to tell the user, or nil when the failure is one
      #   they can acknowledge rather than one that stops the upload
      def error_message
        message = ERROR_MESSAGES[error]
        return nil if message.nil?

        Translation.translate(message)
      end

      # What gets stored on uploads.export_source_check.
      # @return [Hash]
      def to_audit_h
        {
          'file_source_id' => source_id,
          'file_source_name' => source_name,
          'file_export_start_date' => export_start_date&.iso8601,
          'file_export_end_date' => export_end_date&.iso8601,
          'check_error' => error&.to_s,
        }
      end

      # Rebuilds a Result from a stored audit row.
      # @param hash [Hash, nil]
      # @return [Result]
      def self.from_audit_h(hash)
        hash = hash.presence || {}
        new(
          source_id: hash['file_source_id'],
          source_name: hash['file_source_name'],
          export_start_date: parse_stored_date(hash['file_export_start_date']),
          export_end_date: parse_stored_date(hash['file_export_end_date']),
          error: hash['check_error'].presence&.to_sym,
        )
      end

      def self.parse_stored_date(value)
        return nil if value.blank?

        Date.parse(value)
      rescue Date::Error
        nil
      end
    end

    # Reads Export.csv out of a file that was just uploaded, while it is still the
    # request's own tempfile on local disk.
    # @param file [ActionDispatch::Http::UploadedFile]
    # @return [Result]
    def self.for_uploaded_file(file)
      new(file_path: file.tempfile.path, filename: file.original_filename).run
    end

    # @param file_path [String] path to the archive on disk
    # @param filename [String] the name the archive was uploaded under. A request
    #   tempfile is not named after it, and the extension decides which reader applies.
    def initialize(file_path:, filename: nil)
      @file_path = file_path
      @filename = filename.presence || file_path
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
      File.extname(@filename) == SEVEN_ZIP_EXTENSION
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

    # 7z is a different container format, so rubyzip cannot read it. Reach for the same
    # wrapper the import job uses rather than leaving the SourceID unknown.
    # @return [String, Result]
    private def seven_zip_contents
      entry = seven_zip_entry_name
      return entry if entry.is_a?(Result)

      contents = SevenZip.read_entry(source: @file_path, entry: entry, max_bytes: MAX_EXPORT_FILE_BYTES)
      return Result.new(error: :unverifiable) if contents.nil?

      contents
    end

    # @return [String, Result] the archive-relative path of Export.csv
    private def seven_zip_entry_name
      names = SevenZip.entries(source: @file_path)
      return Result.new(error: :unverifiable) if names.nil?

      name = names.find { |n| File.basename(n).casecmp(EXPORT_FILE_NAME).zero? }
      return Result.new(error: :missing_export_file) if name.nil?

      name
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
