###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMIS2020
  class Affiliation < GrdaWarehouse::Import::HMIS2020::Affiliation
    include ::Export::HMIS2020::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Affiliation.hud_csv_headers(version: '2020') )

    self.hud_key = :AffiliationID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :affiliations

  end
end