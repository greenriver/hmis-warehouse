###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Importer::Client', primary_key: [:PersonalID, :data_source_id], query_constraints: [:PersonalID, :data_source_id]
      has_many :loaded_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Loader::Client', primary_key: [:PersonalID, :data_source_id], query_constraints: [:PersonalID, :data_source_id]
    end
  end
end
