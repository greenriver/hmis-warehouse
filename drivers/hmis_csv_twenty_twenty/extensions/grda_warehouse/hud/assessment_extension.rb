###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module AssessmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items, class_name: 'HmisCsvTwentyTwenty::Importer::Assessment', primary_key: [:AssessmentID, :data_source_id], foreign_key: [:AssessmentID, :data_source_id]
      has_many :loaded_items, class_name: 'HmisCsvTwentyTwenty::Loader::Assessment', primary_key: [:AssessmentID, :data_source_id], foreign_key: [:AssessmentID, :data_source_id]
      has_many :involved_in_imports, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :warehouse_record
    end
  end
end
