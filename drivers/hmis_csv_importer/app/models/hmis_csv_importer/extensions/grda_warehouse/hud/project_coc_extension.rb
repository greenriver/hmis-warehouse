###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::GrdaWarehouse::Hud
  module ProjectCocExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::ProjectCoc', primary_key: [:ProjectCoCID, :data_source_id], foreign_key: [:ProjectCoCID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::ProjectCoc', primary_key: [:ProjectCoCID, :data_source_id], foreign_key: [:ProjectCoCID, :data_source_id]
    end
  end
end
