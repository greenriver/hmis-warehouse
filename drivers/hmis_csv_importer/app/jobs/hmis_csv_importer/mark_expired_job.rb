module HmisCsvImporter
  class MarkExpiredJob < ApplicationJob
    #
    # @param data_source_id [Integer, nil] the ID of the data source
    # @param now [DateTime] the time for the purposes of relative time calculation
    # @param retained_imports [Integer] the number of retained import records
    # @param retain_deleted_records_for [Duration] the retention period for deleted records
    def perform(data_source_id: nil, now: DateTime.current, retained_imports: 10, retain_deleted_records_for: 2.weeks)
      @data_source_id = data_source_id
      @now = now.to_datetime
      @expire_deleted_records_before = now - retain_deleted_records_for
      @retained_imports = retained_imports * files_per_import

      models.each do |model|
        process_modal(model)
      end
    end

    protected

    def process_model(model)
      candidates_for_expiration = model.
        where.not(loader_id: recent_import_ids, data_source_id: @data_source_id).
        preload(:destination_record_with_deleted).
        select(:id, model.hud_key, :data_source_id, :DateDeleted, :loader_id)

      puts "#{model.name} total: #{candidates_for_expiration.size}"
      candidates_for_expiration.in_batches(of: 1_000) do |batch|
        expired_ids = []

        batch.each do |record|
          destination = record.destination_record_with_deleted
          expired_ids.push(record.id) if expired?(record, destination)
        end
        batch.where.not(id: expired_ids).update_all(expired: false)
        model.where(id: expired_ids).update_all(expired: true)
      end
      puts "#{model.name} expired: #{candidates_for_expiration.where(expired: true).size}"
    end

    def files_per_import
      GrdaWarehouse::HmisImportConfig.active.
        where(data_source_id: @data_source_id).
        maximum(:file_count)
    end

    def recent_import_ids
      @recent_import_ids = HmisCsvImporter::Loader::LoaderLog.
        where(data_source_id: @data_source_id).
        order(created_at: :desc).
        limit(@retained_imports).pluck(:id)
    end

    def expired?(record, destination)
      # The record is no-longer attached to a destination and not included in the recent loaders (via batch selection)
      return true if destination.nil?

      date_deleted = destination.DateDeleted || record.DateDeleted
      return false if date_deleted.nil?

      # The destination record (or this record) has been deleted for longer than the retention period
      date_deleted < @expire_deleted_records_before
    end

    def models
      # TODO: need to handle importer tables too
      all = [
        HmisCsvImporter::Loader::Loader.loadable_files,
        #  #HmisCsvImporter::Importer::Importer.importable_files,
      ].flat_map(&:values)
      all.filter do |model|
        # keep Export records indefinitely. There's only ever one row of metadata.
        model.name.demodulize != 'Export' && model.reflect_on_association(:destination_record_with_deleted)
      end
    end
  end
end
