###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Importer
  class EnrollmentCoc < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::EnrollmentCoc
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_enrollment_cocs'

    has_one :destination_record, **hud_assoc(:EnrollmentCoCID, 'EnrollmentCoc')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::EnrollmentCoc
    end

    def self.hmis_validations
      {
        HouseholdID: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::Length,
            arguments: { max: 32 },
          },
        ],
        EnrollmentID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        ProjectID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        InformationDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        CoCCode: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.cocs.keys.freeze },
          },
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
      }
    end
  end
end
