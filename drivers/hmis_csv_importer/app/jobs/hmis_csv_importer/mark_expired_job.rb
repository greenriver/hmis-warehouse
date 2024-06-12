module HmisCsvImporter
  class MarkExpiredJob < ApplicationJob
    # @param data_source_id [Integer, nil] the ID of the data source
    # @param retained_imports [Integer] the number of retained import records
    # @param retain_all_records_after [DateTime] the minimum retention period
    def perform(data_source_id: nil, retained_imports: 10, retain_all_records_after: DateTime.current)
      @data_source_id = data_source_id
      @retain_all_records_after = retain_all_records_after
      @retained_imports = retained_imports * files_per_import

      loader_models.each do |model|
        process_loader(model)
      end
      # importer_models.each do |model|
      #   process_importer(model)
      # end
    end

    protected

    def log(str)
      Rails.logger.info(str)
    end

    def process_loader(model)
      candidates_for_expiration = model.
        where(data_source_id: @data_source_id).
        select(:id, model.hud_key, :data_source_id, :DateDeleted, :loader_id)

      log "#{model.table_name} total: #{candidates_for_expiration.size}"
      candidates_for_expiration.in_batches(of: 5_000) do |batch|
        cnt = 0
        benchmark "#{model.table_name} [batch #{cnt += 1}]" do
          recent_loader_ids = query_recent_import_ids(model, batch)
          expired_ids = batch.filter do |record|
            next false if record.loader_id.in?(retained_loader_ids)

            key = record[model.hud_key]
            preserve_ids = recent_loader_ids[key]
            next false if preserve_ids.present? && record.loader_id.in?(preserve_ids)

            true
          end.map(&:id)

          # micro-optimization to reduce updates
          case expired_ids.size
          when 0
            # all records in batch are valid
            batch.update_all(expired: false)
          when batch.size
            # all records in batch are expired
            model.update_all(expired: true)
          else
            # mix of valid and expired
            batch.where.not(id: expired_ids).update_all(expired: false)
            model.where(id: expired_ids).update_all(expired: true)
          end
        end
        # GC every 10 batches
        GC.start if cnt % 10 == 9
      end
      log "#{model.table_name} expired: #{candidates_for_expiration.where(expired: true).size}"
    end

    def process_importer(model)
      # candidates_for_expiration = model.
      #  where(data_source_id: @data_source_id).
      #  select(:id, model.hud_key, :data_source_id, :DateDeleted, :loader_id)
    end

    def benchmark(name)
      rr = nil
      elapsed = Benchmark.realtime { rr = yield }
      log "#{name}: #{elapsed.round(2)}s"
      rr
    end

    # given a batch of loader ids, get the loader ids for the most recent X imports for each record in the batch
    def query_recent_import_ids(model, batch)
      key_field = model.hud_key
      sql = <<~SQL
        SELECT subquery."#{key_field}", loader_id FROM (
          SELECT loader_id, "#{key_field}", row_number() OVER (PARTITION BY "#{key_field}" ORDER BY id DESC) AS row_num
          FROM "#{model.table_name}"
          WHERE id IN (#{batch.map(&:id).join(',')})
        ) subquery
        WHERE subquery.row_num <= #{@retained_imports}
      SQL

      # results = benchmark("#{model.name.demodulize}") { model.connection.select_rows(sql)}
      results = model.connection.select_rows(sql)
      # hud_key => [loader_id]
      results.each_with_object({}) do |ary, h|
        key, id = ary
        h[key] ||= []
        h[key].push(id)
      end
    end

    def files_per_import
      ::GrdaWarehouse::HmisImportConfig.active.where(data_source_id: @data_source_id).maximum(:file_count) || 1
    end

    def retained_loader_ids
      @retained_loader_ids = HmisCsvImporter::Loader::LoaderLog.
        where(data_source_id: @data_source_id).
        where(created_at: @retain_all_records_after...).
        pluck(:id).to_set
    end

    def loader_models
      ::HmisCsvImporter::Loader::Loader.loadable_files.values.filter do |model|
        # keep Export records indefinitely. There's only ever one row of metadata.
        model.name.demodulize != 'Export'
      end
    end

    def importer_models
      HmisCsvImporter::Importer::Importer.importable_files.values.filter do |model|
        # keep Export records indefinitely. There's only ever one row of metadata.
        model.name.demodulize != 'Export'
      end
    end
  end
end
