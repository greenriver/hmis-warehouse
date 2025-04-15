# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    include ::HmisStructure::Affiliation
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Affiliation'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to_with_composite_keys :project, class_name: 'GrdaWarehouse::Hud::Project', keys: [:ProjectID], inverse_of: :affiliations, optional: true
    # NOTE: you can't use hud_assoc for residential project, the keys don't match
    belongs_to :residential_project, class_name: 'GrdaWarehouse::Hud::Project', primary_key: [:ProjectID, :data_source_id], query_constraints: [:ResProjectID, :data_source_id], inverse_of: :affiliations, optional: true
    belongs_to_with_composite_keys :export, class_name: 'GrdaWarehouse::Hud::Export', keys: [:ExportID], inverse_of: :affiliations, optional: true
    belongs_to_with_composite_keys :user, class_name: 'GrdaWarehouse::Hud::User', keys: [:UserID], inverse_of: :affiliations, optional: true
    belongs_to :data_source

    def self.related_item_keys
      [:ProjectID]
    end
  end
end
