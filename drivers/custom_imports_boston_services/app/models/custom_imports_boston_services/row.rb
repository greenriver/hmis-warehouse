###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonServices
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_boston_rows
    belongs_to :file

    has_one :project, through: :enrollment

    belongs_to :client, **GrdaWarehouse::Hud::Client.hud_assoc(:PersonalID, 'Client')
    belongs_to :enrollment, **GrdaWarehouse::Hud::Enrollment.hud_assoc(:PersonalID, 'Enrollment'), optional: true
  end
end
