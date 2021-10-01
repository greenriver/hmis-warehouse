###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items, class_name: '::HmisCsvImporter::Importer::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id]
      has_many :loaded_items, class_name: '::HmisCsvImporter::Loader::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:PersonalID, :data_source_id]
    end
  end
end
