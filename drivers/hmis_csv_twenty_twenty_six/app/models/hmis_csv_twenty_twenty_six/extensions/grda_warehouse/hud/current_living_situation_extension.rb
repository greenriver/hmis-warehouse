###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::GrdaWarehouse::Hud
  module CurrentLivingSituationExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2026, class_name: '::HmisCsvTwentyTwentySix::Importer::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
      has_many :loaded_items_2026, class_name: '::HmisCsvTwentyTwentySix::Loader::CurrentLivingSituation', primary_key: [:CurrentLivingSitID, :data_source_id], foreign_key: [:CurrentLivingSitID, :data_source_id]
    end
  end
end
