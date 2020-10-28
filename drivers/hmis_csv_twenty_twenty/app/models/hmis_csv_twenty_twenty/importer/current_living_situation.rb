###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class CurrentLivingSituation < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::CurrentLivingSituation
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_current_living_situations'

    has_one :destination_record, **hud_assoc(:CurrentLivingSitID, 'CurrentLivingSituation')

    def self.hmis_validations
      {
        CurrentLivingSituation: [
          class: HmisCsvValidation::NonBlank,
        ],
        InformationDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        UserID: [
          class: HmisCsvValidation::NonBlank,
        ],
        DateUpdated: [
          class: HmisCsvValidation::NonBlank,
        ],
        DateCreated: [
          class: HmisCsvValidation::NonBlank,
        ],
        EnrollmentID: [
          class: HmisCsvValidation::NonBlank,
        ],
      }
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:InformationDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::CurrentLivingSituation
    end
  end
end
