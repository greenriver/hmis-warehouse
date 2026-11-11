###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  # CSV access for pre-process hooks. They run before Loader#load_source_files! detects
  # encoding, so files may be in any encoding; reads transcode to UTF-8, and rewrites
  # leave the file as UTF-8. liberal_parsing matches Loader#load_source_file_pg.
  module PreProcessCsv
    module_function

    def read_options(file)
      {
        encoding: [AutoEncodingCsv.detect_encoding(file), 'UTF-8'].compact.join(':'),
        liberal_parsing: true,
      }
    end

    # Yields each row with downcased headers.
    def foreach(file, options = read_options(file), &block)
      CSV.foreach(file, **options, headers: true, header_converters: :downcase, &block)
    end

    # Yields each row (downcased headers) and the output CSV, which already holds the
    # original header line; the block writes the rows to keep.
    def rewrite!(file)
      options = read_options(file)
      Tempfile.create do |clean_file|
        CSV.open(clean_file, 'wb') do |csv|
          csv << CSV.parse_line(File.open(file, encoding: options[:encoding], &:readline), liberal_parsing: true)
          foreach(file, options) { |row| yield row, csv }
        end
        FileUtils.mv(clean_file, file)
      end
    end
  end
end
