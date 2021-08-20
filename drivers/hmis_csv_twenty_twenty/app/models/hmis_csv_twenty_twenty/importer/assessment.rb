###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Assessment < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Assessment
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_assessments'

    has_one :destination_record, **hud_assoc(:AssessmentID, 'Assessment')

    def self.hmis_validations
      {
        EnrollmentID: [
          class: HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvValidation::NonBlank,
        ],
        AssessmentDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        AssessmentLocation: [
          class: HmisCsvValidation::NonBlank,
        ],
        AssessmentType: [
          {
            class: HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.assessment_types.keys.map(&:to_s).freeze },
          },
        ],
        AssessmentLevel: [
          {
            class: HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.assessment_levels.keys.map(&:to_s).freeze },
          },
        ],
        PrioritizationStatus: [
          {
            class: HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.prioritization_statuses.keys.map(&:to_s).freeze },
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
