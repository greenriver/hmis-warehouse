###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Importer
  class AssessmentQuestion < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::AssessmentQuestion
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_assessment_questions'

    has_one :destination_record, **hud_assoc(:AssessmentQuestionID, 'AssessmentQuestion')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::AssessmentQuestion
    end

    def self.hmis_validations
      {
        AssessmentID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        EnrollmentID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
      }
    end
  end
end
