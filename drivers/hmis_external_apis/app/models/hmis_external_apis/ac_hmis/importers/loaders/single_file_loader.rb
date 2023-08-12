###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common behavior for loader that expects one csv file
module HmisExternalApis::AcHmis::Importers::Loaders
  class SingleFileLoader < BaseLoader
    # filename defined in subclass
    def data_file_provided?
      reader.file_present?(filename)
    end

    def table_names
      [model_class.table_name]
    end

    protected

    def rows
      reader.rows(filename)
    end
  end
end
