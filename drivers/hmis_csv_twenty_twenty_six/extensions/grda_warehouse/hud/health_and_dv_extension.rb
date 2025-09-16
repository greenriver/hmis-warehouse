###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::GrdaWarehouse::Hud
  module HealthAndDvExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2026, class_name: '::HmisCsvTwentyTwentySix::Importer::HealthAndDv', primary_key: [:HealthAndDVID, :data_source_id], query_constraints: [:HealthAndDVID, :data_source_id]
      has_many :loaded_items_2026, class_name: '::HmisCsvTwentyTwentySix::Loader::HealthAndDv', primary_key: [:HealthAndDVID, :data_source_id], query_constraints: [:HealthAndDVID, :data_source_id]
    end
  end
end
