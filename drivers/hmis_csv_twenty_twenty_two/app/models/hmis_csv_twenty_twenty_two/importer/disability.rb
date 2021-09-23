###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Importer
  class Disability < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Disability
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_disabilities'

    has_one :destination_record, **hud_assoc(:DisabilitiesID, 'Disability')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:InformationDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Disability
    end

    def self.hmis_validations
      {
        EnrollmentID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        InformationDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        DataCollectionStage: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.data_collection_stages.keys.map(&:to_s).freeze },
          },
        ],
        DisabilityType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.disability_types.keys.map(&:to_s).freeze },
          },
        ],
        DisabilityResponse: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.disability_responses.keys.map(&:to_s).freeze },
          },
        ],
        IndefiniteAndImpairs: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.no_yes_reasons_for_missing_data_options.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
