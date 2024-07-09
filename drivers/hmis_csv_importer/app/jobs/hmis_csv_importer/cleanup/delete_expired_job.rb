module HmisCsvImporter::Cleanup
  class DeleteExpiredJob < ApplicationJob
    include ReportingConcern

    def perform
      models.each do |model|
        benchmark "delete expired from #{model.table_name}" do
          expired = model.with_deleted.where(expired: true)
          # delete in batches to reduce impact on db
          expired.in_batches(of: 50_000).delete_all
          # can't vacuum in a transaction (running in a test context)
          model.vacuum_table if model.connection.open_transactions.zero?
        end
      end
    end

    protected

    def models
      (
        ::HmisCsvImporter::Importer::Importer.expiring_models +
        ::HmisCsvImporter::Loader::Loader.expiring_models +
        ::HmisCsvTwentyTwentyTwo.expiring_importer_classes +
        ::HmisCsvTwentyTwentyTwo.expiring_loader_classes +
        ::HmisCsvTwentyTwenty.expiring_importer_classes +
        ::HmisCsvTwentyTwenty.expiring_loader_classes
      )
    end
  end
end
