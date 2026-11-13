###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::GrdaWarehouse::Hud
  module EnrollmentCocExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::EnrollmentCoc', primary_key: [:EnrollmentCoCID, :data_source_id], foreign_key: [:EnrollmentCoCID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::EnrollmentCoc', primary_key: [:EnrollmentCoCID, :data_source_id], foreign_key: [:EnrollmentCoCID, :data_source_id]
    end
  end
end
