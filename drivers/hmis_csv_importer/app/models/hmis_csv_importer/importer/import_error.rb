###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Importer
  class ImportError < GrdaWarehouseBase
    self.table_name = 'hmis_csv_import_errors'

    belongs_to :importer_log
    belongs_to :source, polymorphic: true, optional: true
  end
end
