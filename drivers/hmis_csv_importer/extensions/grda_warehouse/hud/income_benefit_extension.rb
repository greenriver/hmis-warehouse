###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse::Hud
  module IncomeBenefitExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], foreign_key: [:IncomeBenefitsID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], foreign_key: [:IncomeBenefitsID, :data_source_id]
    end
  end
end
