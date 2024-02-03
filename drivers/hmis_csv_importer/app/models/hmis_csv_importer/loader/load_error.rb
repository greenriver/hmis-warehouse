###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class LoadError < GrdaWarehouseBase
    self.table_name = 'hmis_csv_load_errors'
    belongs_to :loader_log, optional: true
  end
end
