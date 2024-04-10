###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse::Hud
  module FunderExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::Funder', primary_key: [:FunderID, :data_source_id], foreign_key: [:FunderID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::Funder', primary_key: [:FunderID, :data_source_id], foreign_key: [:FunderID, :data_source_id]
      has_many :import_overrides, class_name: 'HmisCsvImporter::ImportOverride', primary_key: [hud_key, :data_source_id], foreign_key: [:matched_hud_key, :data_source_id]
    end
  end
end
