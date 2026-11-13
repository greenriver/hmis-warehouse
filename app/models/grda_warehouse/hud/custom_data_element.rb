###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Hud
  class CustomDataElement < Base
    include HudSharedScopes
    include ::HmisStructure::CustomDataElement
    include ::HmisStructure::Shared

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
