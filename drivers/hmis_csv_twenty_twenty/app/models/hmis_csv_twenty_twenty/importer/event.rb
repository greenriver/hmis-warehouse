###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Event < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Event
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_events'

    has_one :destination_record, **hud_assoc(:EventID, 'Event')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.
        importable.
        joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:EventDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Event
    end

    def self.hmis_validations
      {
        EnrollmentID: [
          class: HmisCsvValidation::NonBlank,
        ],
        PersonalID: [
          class: HmisCsvValidation::NonBlank,
        ],
        EventDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        Event: [
          {
            class: HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.events.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
