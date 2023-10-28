###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ExternalFileUtils
  extend ActiveSupport::Concern

  class_methods do
    # Process a file to clean up if the last line does not have a valid line ending.
    # Will process the file into a Tempfile.
    # @param filename [String] the name of the file to process
    # @param encoding [String] a valid file encoding value (e.g., 'bom|UTF-8')
    def fix_bad_line_endings(filename, encoding)
      tmp_file = ::Tempfile.new(filename)
      file_with_bad_line_endings = false

      File.open(filename, 'r', encoding: encoding) do |file|
        file_with_bad_line_endings = ! valid_line_endings?(file)
      end

      if file_with_bad_line_endings
        File.open(filename, 'r', encoding: encoding) do |file|
          copy_length = file.stat.size - 2
          Rails.logger.debug "Correcting bad line ending in #{filename}"
          File.copy_stream(file, tmp_file, copy_length, 0)
          tmp_file.write("\n")
          tmp_file.close
        end
        FileUtils.cp(tmp_file, filename)
      end
    ensure
      tmp_file&.close
      tmp_file&.unlink
    end

    # Check valid line endings. The file will be opened, so, it must exist.
    # @param file [File] File to be inspected
    # @return [Boolean] does the file conform to unix or windows line endings
    def valid_line_endings?(file)
      return false if file.stat.size < 10

      position = file.pos
      first_line = file.first
      first_line_final_characters = first_line.last(2)
      file.seek(position)
      file.seek(file.stat.size - 2)
      last_two_chars = file.read
      file.seek(position)

      # sometimes the final return is missing
      return true unless last_two_chars.include?("\n") || last_two_chars.include?("\r")
      # windows
      return true if last_two_chars == "\r\n" && first_line_final_characters == "\r\n"
      # unix
      return true if last_two_chars != "\r\n" && last_two_chars.last == "\n" && first_line_final_characters.last == "\n"

      false
    end
  end
end
