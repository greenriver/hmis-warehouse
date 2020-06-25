###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Affiliation < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::Affiliation
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_affiliations'

    has_one :destination_record, **hud_assoc(:AffiliationID, 'Affiliation')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable  Lint/UnusedMethodArgument
      return none unless project_ids.present?

      GrdaWarehouse::Hud::Affiliation.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end
  end
end
