###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Export < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::Export
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_exports'

    has_one :destination_record, **hud_assoc(:ExportID, 'Export')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      GrdaWarehouse::Hud::Export.where(data_source_id: data_source_id)
    end

    # Don't ever mark these for deletion
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    end
  end
end
