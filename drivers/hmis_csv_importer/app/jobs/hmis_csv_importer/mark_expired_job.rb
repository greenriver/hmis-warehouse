module HmisCsvImporter
  class MarkExpiredJob < ApplicationJob
    def perform(now: DateTime.current, recent_imports_to_keep: 10, keep_deleted_records_for: 2.weeks)
      @now = now.to_datetime
      @expire_deleted_records_before = now - keep_deleted_records_for
      @recent_imports_to_keep = recent_imports_to_keep

      total = 0
      models.each do |model|
        # FIXME, should include select clause to improve performance
        candidates_for_expiration = model.
          where.not(loader_id: recent_import_ids).
          preload(:destination_record_with_deleted)

        puts "#{model.name} total: #{candidates_for_expiration.size}"
        candidates_for_expiration.in_batches(of: 1_000) do |batch|
          expired_ids = []

          batch.each do |record|
            destination = record.destination_record_with_deleted
            expired_ids.push(record.id) if expired?(record, destination)
          end
          batch.where.not(id: expired_ids).update_all(expired: false)
          model.where(id: expired_ids).update_all(expired: true)
          total += expired_ids.size
        end
        puts "#{model.name} expired: #{candidates_for_expiration.where(expired: true).size}"
      end

      total
    end

    protected

    def recent_import_ids
      @recent_import_ids ||= HmisCsvImporter::Loader::LoaderLog.order(created_at: :desc).limit(@recent_imports_to_keep).pluck(:id)
    end

    def expired?(record, destination)
      date_deleted = destination&.DateDeleted || record.DateDeleted
      return true if date_deleted && date_deleted < @expire_deleted_records_before

      false
    end

    def models
      # TODO: need to handle importer tables too
      all = [
        HmisCsvImporter::Loader::Loader.loadable_files,
        #  #HmisCsvImporter::Importer::Importer.importable_files,
      ].flat_map(&:values)
      all.filter { |m| m.reflect_on_association(:destination_record_with_deleted) }
    end
  end
end
