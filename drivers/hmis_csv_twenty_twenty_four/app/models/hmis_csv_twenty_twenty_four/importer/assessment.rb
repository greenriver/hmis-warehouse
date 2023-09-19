###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class Assessment < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Assessment
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_assessments'
    self.primary_key = 'id'

    has_one :destination_record, **hud_assoc(:AssessmentID, 'Assessment')

    def self.hmis_validations
      {
        EnrollmentID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        AssessmentDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        AssessmentLocation: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        AssessmentType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.assessment_types.keys.map(&:to_s).freeze },
          },
        ],
        AssessmentLevel: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.assessment_levels.keys.map(&:to_s).freeze },
          },
        ],
        PrioritizationStatus: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.prioritization_statuses.keys.map(&:to_s).freeze },
          },
        ],
      }
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:AssessmentDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Assessment
    end
  end
end
