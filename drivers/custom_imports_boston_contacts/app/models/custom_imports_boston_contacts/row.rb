###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonContacts
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_contacts_rows
    belongs_to :import_file

    belongs_to :client, **GrdaWarehouse::Hud::Client.hud_assoc(:PersonalID, 'Client')
  end
end
