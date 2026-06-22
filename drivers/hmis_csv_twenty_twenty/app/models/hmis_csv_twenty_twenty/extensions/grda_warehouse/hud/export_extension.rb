###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module ExportExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2020, class_name: 'HmisCsvTwentyTwenty::Importer::Export', primary_key: [:ExportID, :data_source_id], foreign_key: [:ExportID, :data_source_id]
      has_many :loaded_items_2020, class_name: 'HmisCsvTwentyTwenty::Loader::Export', primary_key: [:ExportID, :data_source_id], foreign_key: [:ExportID, :data_source_id]
    end
  end
end
