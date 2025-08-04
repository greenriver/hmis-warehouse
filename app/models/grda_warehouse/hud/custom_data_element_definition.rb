# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class CustomDataElementDefinition < Base
    include HudSharedScopes
    include ::HmisStructure::CustomDataElementDefinition
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'CustomDataElementDefinitions'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    def self.index_predicate
      arel_table[:CustomDataElementDefinitionID].not_eq(nil).to_sql
    end
  end
end
