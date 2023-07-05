###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class ClientImport < ::GrdaWarehouse::CustomImports::ImportFile
    def self.import_prefix
      'client'
    end
  end
end
