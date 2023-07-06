###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class ClientImport < ::GrdaWarehouse::CustomImports::ImportFile
    include CsvImportConcern
    def self.import_prefix
      'client'
    end

    private def associated_class
      Financial::Client
    end

    private def conflict_target
      [:external_client_id, :data_source_id]
    end

    private def header_lookup
      # All headers match except client_id
      {
        'client_id' => 'external_client_id',
      }
    end
  end
end
