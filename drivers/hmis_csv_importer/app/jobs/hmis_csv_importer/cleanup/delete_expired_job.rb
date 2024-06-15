module HmisCsvImporter::Cleanup
  class DeleteExpiredJob < ApplicationJob
    include ReportingConcern

    # @param data_source_id [Integer] the ID of the data source
    def perform(data_source_id: nil)
      models.each do |model|
        benchmark "delete expired from #{model.table_name}" do
          expired = model.with_deleted.where(data_source_id: data_source_id).where(expired: true)
          # delete in batches to reduce impact on db
          expired.in_batches(of: 5_000).delete_all
        end
        benchmark "vacuum #{model.table_name}" do
          # can't vacuum in a transaction (running in a test context)
          model.vacuum_table if model.connection.open_transactions.zero?
        end
      end
    end

    protected

    def models
      ::HmisCsvImporter::Importer::Importer.expiring_models + ::HmisCsvImporter::Loader::Loader.expiring_models
    end
  end
end
