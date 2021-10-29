###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonAssessmentLookups
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_al_rows
    belongs_to :import_file
  end
end
