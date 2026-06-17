###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Financial
  class ProviderImport < ::GrdaWarehouse::CustomImports::ImportFile
    include CsvImportConcern
    def self.import_prefix
      'provider'
    end

    private def associated_class
      Financial::Provider
    end

    private def conflict_target
      [:provider_id, :data_source_id]
    end

    private def header_lookup
      # All headers match
      {}
    end
  end
end
