###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class FileReader
    attr_reader :dir
    def initialize(dir)
      @dir = dir
    end

    def file_present?(filename)
      File.exist?("#{dir}/#{filename}")
    end

    def rows(filename:, sheet_number: 0, header_row_number: 3)
      case filename
      when /\.xlsx$/i
        XlsxFile.new(filename: "#{dir}/#{filename}", sheet_number: sheet_number, header_row_number: header_row_number)
      else
        raise "File format not supported for \"#{filename}\". Expected xlsx"
      end
    end
  end
end