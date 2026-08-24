###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  class RowProcessingNote < GrdaWarehouseBase
    self.table_name = 'hmis_csv_row_processing_notes'
    belongs_to :loader_log, optional: true
  end
end
