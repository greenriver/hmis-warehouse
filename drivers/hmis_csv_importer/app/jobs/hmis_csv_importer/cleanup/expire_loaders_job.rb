module HmisCsvImporter::Cleanup
  class ExpireLoadersJob < ExpireBaseJob
    protected

    def process_model(model)
      candidates = model.
        with_deleted.
        where(data_source_id: @data_source_id).
        select(:id, model.hud_key, :loader_id)

      cnt = 0
      log "#{model.table_name} total: #{candidates.size}"
      candidates.in_batches(of: 5_000) do |batch|
        sequence_protected_id_map = query_sequence_protected_ids(model, batch)
        expired_ids = []
        valid_ids = []
        batch.each do |record|
          if record.loader_id.in?(age_protected_ids)
            valid_ids << record.id
            next
          end

          sequence_protected_ids = sequence_protected_id_map[record[model.hud_key]]
          if sequence_protected_ids.present? && record.loader_id.in?(sequence_protected_ids)
            valid_ids << record.id
            next
          end
          expired_ids << record.id
        end.map(&:id)

        model.where(id: valid_ids).update_all(expired: false) if valid_ids.any?
        model.where(id: expired_ids).update_all(expired: true) if expired_ids.any?
        # GC every 10 batches
        cnt += 1
        GC.start if cnt % 10 == 9
      end
      log "#{model.table_name} expired: #{candidates.where(expired: true).size}"
    end

    # get the loader ids for the most recent X imports for each record in the batch
    # @return [Hash] { hud_key => [..., loader_id] }
    def query_sequence_protected_ids(model, batch)
      key_field = model.hud_key
      sql = <<~SQL
        SELECT subquery."#{key_field}", loader_id FROM (
          SELECT loader_id, "#{key_field}", row_number() OVER (PARTITION BY "#{key_field}" ORDER BY id DESC) AS row_num
          FROM "#{model.table_name}"
          WHERE id IN (#{batch.map(&:id).join(',')})
        ) subquery
        WHERE subquery.row_num <= #{@retain_log_count}
      SQL

      results = model.connection.select_rows(sql)
      results.each_with_object({}) do |ary, h|
        key, id = ary
        h[key] ||= []
        h[key].push(id)
      end
    end

    def age_protected_ids
      @age_protected_ids ||= HmisCsvImporter::Loader::LoaderLog.
        where(data_source_id: @data_source_id).
        where(created_at: @retain_after_date...).
        pluck(:id).to_set
    end

    def models
      ::HmisCsvImporter::Loader::Loader.loadable_files.values.filter do |model|
        # keep Export records indefinitely. There's only ever one row of metadata.
        model.name.demodulize != 'Export'
      end
    end
  end
end
