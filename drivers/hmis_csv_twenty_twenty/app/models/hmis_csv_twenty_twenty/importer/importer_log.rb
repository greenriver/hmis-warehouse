###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class ImporterLog < GrdaWarehouseBase
    self.table_name = 'hmis_csv_importer_logs'
    has_many :import_errors
    has_many :import_validations
  end
end
