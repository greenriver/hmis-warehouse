###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module CurrentLivingSituationExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2020, class_name: 'HmisCsvTwentyTwenty::Importer::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
      has_many :loaded_items_2020, class_name: 'HmisCsvTwentyTwenty::Loader::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
    end
  end
end
