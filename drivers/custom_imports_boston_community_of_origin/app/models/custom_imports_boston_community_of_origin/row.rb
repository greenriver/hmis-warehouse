###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin
  class Row < GrdaWarehouseBase
    self.table_name = :custom_imports_b_coo_rows

    belongs_to :import_file, optional: true
    has_one :client_location, class_name: 'ClientLocationHistory::Location', as: :source

    has_one :project, through: :enrollment
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:personal_id, :data_source_id], optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: [:EnrollmentID, :data_source_id], foreign_key: [:enrollment_id, :data_source_id], optional: true
  end
end
