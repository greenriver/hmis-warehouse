###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module HealthAndDvExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2020, class_name: 'HmisCsvTwentyTwenty::Importer::HealthAndDv', primary_key: [:HealthAndDVID, :data_source_id], foreign_key: [:HealthAndDVID, :data_source_id]
      has_many :loaded_items_2020, class_name: 'HmisCsvTwentyTwenty::Loader::HealthAndDv', primary_key: [:HealthAndDVID, :data_source_id], foreign_key: [:HealthAndDVID, :data_source_id]
    end
  end
end
