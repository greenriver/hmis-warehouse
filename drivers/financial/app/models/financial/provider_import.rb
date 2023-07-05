###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class ProviderImport < ::GrdaWarehouse::CustomImports::ImportFile
    def self.import_prefix
      'provider'
    end
  end
end
