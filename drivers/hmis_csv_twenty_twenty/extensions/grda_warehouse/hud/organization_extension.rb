###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module OrganizationExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items, class_name: 'HmisCsvTwentyTwenty::Importer::Organization', primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id]
      has_many :loaded_items, class_name: 'HmisCsvTwentyTwenty::Loader::Organization', primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id]
      has_many :involved_in_imports, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :record
    end
  end
end
