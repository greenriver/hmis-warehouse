###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Event < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Event
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_events'

    has_one :destination_record, **hud_assoc(:EventID, 'Event')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range)).
        where(warehouse_class.arel_table[:EventDate].lteq(date_range.last))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Event
    end
  end
end
