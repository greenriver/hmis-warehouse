###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::GrdaWarehouse::Hud
  module AssessmentResultExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2026, class_name: '::HmisCsvTwentyTwentySix::Importer::AssessmentResult', primary_key: [:AssessmentResultID, :data_source_id], foreign_key: [:AssessmentResultID, :data_source_id]
      has_many :loaded_items_2026, class_name: '::HmisCsvTwentyTwentySix::Loader::AssessmentResult', primary_key: [:AssessmentResultID, :data_source_id], foreign_key: [:AssessmentResultID, :data_source_id]
    end
  end
end
