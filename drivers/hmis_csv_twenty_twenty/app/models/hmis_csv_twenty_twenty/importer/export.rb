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

    # Used to set the effective end date of the warehouse export record for future
    # processing
    def effective_export_end_date
      @effective_export_end_date ||= (importable_files.except('Export.csv').map do |_, klass|
        klass.where(importer_log_id: importer_log_id).maximum(:DateUpdated)
      end.compact + ['1900-01-01'.to_date]).max
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      GrdaWarehouse::Hud::Export.where(data_source_id: data_source_id)
    end

    # Don't ever mark these for deletion
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    end
  end
end
