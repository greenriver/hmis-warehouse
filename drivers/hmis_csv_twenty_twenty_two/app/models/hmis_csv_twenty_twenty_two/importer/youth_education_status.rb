###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Importer
  class YouthEducationStatus < GrdaWarehouse::Hud::Base
    include ::HmisStructure::YouthEducationStatus
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_youth_education_statuses'
    self.primary_key = 'id'

    has_one :destination_record, **hud_assoc(:YouthEducationStatusID, 'YouthEducationStatus')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:InformationDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::YouthEducationStatus
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
            arguments: { valid_options: HudUtility.data_collection_stages.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
