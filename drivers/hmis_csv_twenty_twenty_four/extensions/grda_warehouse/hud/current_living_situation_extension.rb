###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud
  module CurrentLivingSituationExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Importer::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
      has_many :loaded_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Loader::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
    end
  end
end
