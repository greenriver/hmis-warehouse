###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class TransactionImport < ::GrdaWarehouse::CustomImports::ImportFile
    def self.import_prefix
      'transaction'
    end
  end
end
