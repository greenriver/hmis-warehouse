###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    include ::HMIS::Structure::Affiliation
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Affiliation'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :affiliations, optional: true
    # NOTE: you can't use hud_assoc for residential project, the keys don't match
    belongs_to :residential_project, class_name: 'GrdaWarehouse::Hud::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ResProjectID, :data_source_id], inverse_of: :affiliations, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :affiliations, optional: true, optional: true
    belongs_to :data_source, optional: true

    def self.related_item_keys
      [:ProjectID]
    end
  end
end
