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

    def import!(force = false)
      return unless check_hour || force

      start_import
      fetch_and_load
      complete_import
      post_process
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

    private def post_process
      Financial::Client.match_warehouse_clients
    end
  end
end
