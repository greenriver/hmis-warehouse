# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud
  module IncomeBenefitExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Importer::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], query_constraints: [:IncomeBenefitsID, :data_source_id]
      has_many :loaded_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Loader::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], query_constraints: [:IncomeBenefitsID, :data_source_id]
    end
  end
end
