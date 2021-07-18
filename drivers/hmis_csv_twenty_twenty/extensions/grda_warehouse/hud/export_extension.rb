###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module ExportExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items, class_name: 'HmisCsvTwentyTwenty::Importer::Export', primary_key: [:ExportID, :data_source_id], foreign_key: [:ExportID, :data_source_id]
      has_many :loaded_items, class_name: 'HmisCsvTwentyTwenty::Loader::Export', primary_key: [:ExportID, :data_source_id], foreign_key: [:ExportID, :data_source_id]
      has_many :involved_in_imports, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :warehouse_record
    end
  end
end
