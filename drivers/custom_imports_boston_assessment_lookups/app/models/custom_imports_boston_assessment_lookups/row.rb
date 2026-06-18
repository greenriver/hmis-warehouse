###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CustomImportsBostonAssessmentLookups
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_al_rows
    belongs_to :import_file
  end
end
