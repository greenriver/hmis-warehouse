###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Project < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Project
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_projects'

    has_one :destination_record, **hud_assoc(:ProjectID, 'Project')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.where(data_source_id: data_source_id, ProjectID: project_ids)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Project
    end

    # Don't ever mark these for deletion
    # def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
    # end

    # We don't mark these as dead, so the existing data is just those that match the appropriate scope
    # def self.existing_destination_data(data_source_id:, project_ids:, date_range:)
    #   involved_warehouse_scope(
    #     data_source_id: data_source_id,
    #     project_ids: project_ids,
    #     date_range: date_range,
    #   )
    # end
  end
end
