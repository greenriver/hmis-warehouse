# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_coo_rows

    belongs_to :import_file, optional: true
    has_one :client_location, class_name: 'ClientLocationHistory::Location', as: :source

    has_one :project, through: :enrollment
    belongs_with_composite_keys :client, class_name: 'GrdaWarehouse::Hud::Client', keys: [:personal_id], optional: true
    belongs_with_composite_keys :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', keys: [:enrollment_id], optional: true
  end
end
