###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CustomImportsBostonContacts
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_contacts_rows
    belongs_to :import_file

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:personal_id, :data_source_id], optional: true
  end
end
