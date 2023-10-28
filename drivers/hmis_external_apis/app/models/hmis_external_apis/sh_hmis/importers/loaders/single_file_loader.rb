###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common behavior for loader that expects one csv file
module HmisExternalApis::ShHmis::Importers::Loaders
  class SingleFileLoader < BaseLoader
    def runnable?
      # filename defined in subclass
      super && reader.file_present?(filename)
    end

    protected

    def rows
      reader.rows(filename)
    end
  end
end
