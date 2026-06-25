###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwenty::Importer
  class ImportError < GrdaWarehouseBase
    self.table_name = 'hmis_csv_import_errors'

    belongs_to :importer_log
    belongs_to :source, polymorphic: true, optional: true
  end
end
