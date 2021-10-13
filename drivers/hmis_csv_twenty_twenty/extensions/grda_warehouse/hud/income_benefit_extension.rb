###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module IncomeBenefitExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2020, class_name: 'HmisCsvTwentyTwenty::Importer::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], foreign_key: [:IncomeBenefitsID, :data_source_id]
      has_many :loaded_items_2020, class_name: 'HmisCsvTwentyTwenty::Loader::IncomeBenefit', primary_key: [:IncomeBenefitsID, :data_source_id], foreign_key: [:IncomeBenefitsID, :data_source_id]
    end
  end
end
