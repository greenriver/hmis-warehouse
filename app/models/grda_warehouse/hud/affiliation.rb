###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    include ::HmisStructure::Affiliation
    include ::HmisStructure::Shared
    # Extensions from drivers — see ADR 0007
    include HmisCsvImporter::GrdaWarehouse::Hud::AffiliationExtension
    include HmisCsvTwentyTwenty::GrdaWarehouse::Hud::AffiliationExtension
    include HmisCsvTwentyTwentyFour::GrdaWarehouse::Hud::AffiliationExtension
    include HmisCsvTwentyTwentySix::GrdaWarehouse::Hud::AffiliationExtension

    attr_accessor :source_id

    self.table_name = 'Affiliation'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :affiliations, optional: true
    # NOTE: you can't use hud_assoc for residential project, the keys don't match
    belongs_to :residential_project, class_name: 'GrdaWarehouse::Hud::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ResProjectID, :data_source_id], inverse_of: :affiliations, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :affiliations, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :affiliations, optional: true
    belongs_to :data_source

    def self.related_item_keys
      [:ProjectID]
    end
  end
end
