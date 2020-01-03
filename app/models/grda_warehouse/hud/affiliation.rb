###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    self.table_name = 'Affiliation'
    self.hud_key = :AffiliationID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :AffiliationID,
        :ProjectID,
        :ResProjectID,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :affiliations
    # NOTE: you can't use hud_assoc for residential project, the keys don't match
    belongs_to :residential_project, class_name: 'GrdaWarehouse::Hud::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ResProjectID, :data_source_id], inverse_of: :affiliations
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :affiliations
    belongs_to :data_source

    def self.related_item_keys
      [:ProjectID]
    end
  end
end
