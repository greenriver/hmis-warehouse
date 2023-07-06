###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class TransactionImport < ::GrdaWarehouse::CustomImports::ImportFile
    include CsvImportConcern
    def self.import_prefix
      'transaction'
    end

    private def associated_class
      Financial::Transaction
    end

    private def conflict_target
      [:transaction_id, :data_source_id]
    end

    private def header_lookup
      # All headers match except client_id
      {
        'client_id' => 'external_client_id',
      }
    end
  end
end
