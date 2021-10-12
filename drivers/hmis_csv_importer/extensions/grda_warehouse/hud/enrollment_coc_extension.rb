###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse::Hud
  module EnrollmentCocExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::EnrollmentCoc', primary_key: [:EnrollmentCoCID, :data_source_id], foreign_key: [:EnrollmentCoCID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::EnrollmentCoc', primary_key: [:EnrollmentCoCID, :data_source_id], foreign_key: [:EnrollmentCoCID, :data_source_id]
    end
  end
end
