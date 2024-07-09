module HmisCsvImporter::Cleanup
  class DeleteExpiredJob < ApplicationJob
    include ReportingConcern

    def perform
      batch_size = 250_000
      models.each do |model|
        benchmark "delete expired from #{model.table_name}" do
          min_id = model.minimum(:id) || 0
          max_id = model.maximum(:id) || 0
          i = 0
          # delete in batches to reduce impact on db
          while min_id <= max_id
            model.where(id: min_id .. min_id + batch_size, expired: true).delete_all
            min_id += batch_size

            # can't vacuum in a transaction (running in a test context)
            model.vacuum_table if model.connection.open_transactions.zero? && i.positive? && (i % 10) == 0
            i += 1
          end
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
