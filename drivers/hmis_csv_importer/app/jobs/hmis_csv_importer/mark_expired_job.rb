module HmisCsvImporter
  class MarkExpiredJob < ApplicationJob

    def perform(now: DateTime.current, recent_imports_to_keep: 10, keep_deleted_records_for: 2.weeks)
      @now = now.to_datetime
      @expire_deleted_records_before = now - keep_deleted_records_for
      @recent_imports_to_keep = recent_imports_to_keep

      models.each do |model|
        candidates_for_expiration = model.
          where(expired: nil).
          # where.not(loader_id: recent_import_ids).
          preload(:destination_record_with_deleted)

        candidates_for_expiration.in_batches do |batch|
          expired_ids = []
          batch.each do |record|
            destination = record.destination_record_with_deleted
            expired.push(record.id) if expired?(record, destination)
          end
          model.where(id: expired_ids).update_all(expired: true)
        end
      end
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
      #[
      #  HmisCsvImporter::Loader::Loader.loadable_files,
      #  #HmisCsvImporter::Importer::Importer.importable_files,
      #].flat_map(&:values)
      [HmisCsvTwentyTwentyFour::Loader::YouthEducationStatus]
    end
  end
end
