###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Exit < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Exit
    include ImportConcern
    include ArelHelper

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_exits'

    has_one :destination_record, **hud_assoc(:ExitID, 'Exit')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      # this has to be a bit convoluted because active record doesn't rename the exit joins appropriately
      warehouse_class.where(
        id: GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range).
          joins(:project).
          merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
          select(ex_t[:id]),
      )
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Exit
    end
  end
end
