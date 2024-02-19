###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class HmisParticipation < GrdaWarehouse::Hud::Base
    include ::HmisStructure::HmisParticipation
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_hmis_participations'

    has_one :destination_record, **hud_assoc(:HMISParticipationID, 'HmisParticipation')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::HmisParticipation
    end

    def self.hmis_validations
      {
        HMISParticipationID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        ProjectID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        HMISParticipationType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.hmis_participation_types.keys.map(&:to_s).freeze },
          },
        ],
        HMISParticipationStatusStartDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
      }
    end
  end
end
