###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImports::BostonService
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_boston_rows
    belongs_to :file
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :project, through: :enrollment, optional: true
  end
end
