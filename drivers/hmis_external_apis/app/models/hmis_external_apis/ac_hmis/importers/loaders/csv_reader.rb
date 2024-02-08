###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class CsvReader
    attr_reader :dir
    def initialize(dir)
      @dir = dir
    end

    def file_present?(filename)
      File.exist?("#{dir}/#{filename}")
    end

    def rows(filename)
      CsvFile.new("#{dir}/#{filename}")
    end
  end
end
