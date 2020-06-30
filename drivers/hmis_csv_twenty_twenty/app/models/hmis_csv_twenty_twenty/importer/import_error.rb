###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class ImportError < GrdaWarehouseBase
    self.table_name = 'hmis_csv_import_errors'

    belongs_to :importer_log
  end
end
