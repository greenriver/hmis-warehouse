###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Service < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Service
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_services'

    has_one :destination_record, **hud_assoc(:ServicesID, 'Service')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.importable.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:DateProvided].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Service
    end

    def self.hmis_validations
      {
        EnrollmentID: [
          class: HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvValidation::NonBlank,
        ],
        DateProvided: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        RecordType: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.record_types.keys.map(&:to_s).freeze },
          },
        ],
        TypeProvided: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
        ],
      }
    end
  end
end
