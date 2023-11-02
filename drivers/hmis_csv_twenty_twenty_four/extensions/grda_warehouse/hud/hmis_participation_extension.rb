###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud
  module HmisParticipationExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Importer::HmisParticipation', primary_key: [:HMISParticipationID, :data_source_id], foreign_key: [:HMISParticipationID, :data_source_id]
      has_many :loaded_items_2024, class_name: '::HmisCsvTwentyTwentyFour::Loader::HmisParticipation', primary_key: [:HMISParticipationID, :data_source_id], foreign_key: [:HMISParticipationID, :data_source_id]
    end
  end
end
