###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class CeParticipation < GrdaWarehouse::Hud::Base
    include ::HmisStructure::CeParticipation
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_ce_participations'

    has_one :destination_record, **hud_assoc(:CEParticipationID, 'CeParticipation')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::CeParticipation
    end

    def self.hmis_validations
      {
        CEParticipationID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        ProjectID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
      }
    end
  end
end
