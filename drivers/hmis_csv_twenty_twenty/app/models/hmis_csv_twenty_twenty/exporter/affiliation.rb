###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class Affiliation < GrdaWarehouse::Import::HmisTwentyTwenty::Affiliation
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::Affiliation.hud_csv_headers(version: '2020'))

    self.hud_key = :AffiliationID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :affiliations
  end
end
