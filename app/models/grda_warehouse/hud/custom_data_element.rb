# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class CustomDataElement < Base
    include HudSharedScopes
    include ::HmisStructure::CustomDataElement
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'CustomDataElements'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    # NOTE: this relationship is different from the relationship used and setup in the OP HMIS
    # this one follows our standard import associations. As imported CDEs will not be
    # available in the HMIS.
    belongs_to :custom_data_element_definition, **hud_assoc(:CustomDataElementDefinitionID, 'CustomDataElementDefinition'), optional: true

    def self.index_predicate
      arel_table[:CustomDataElementID].not_eq(nil).to_sql
    end
  end
end
