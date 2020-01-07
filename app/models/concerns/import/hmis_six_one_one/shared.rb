###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Import::HMISSixOneOne::Shared # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern
  included do
    include NotifierConfig

    attr_accessor :file_path

    after_initialize do
      setup_notifier('HMIS Importer 6.11')
    end
    # Provide access to all of the HUD headers with snake case
    # eg: ProjectID is aliased to project_id
    # hud_csv_headers.each do |att|
    #   alias_attribute att.to_s.underscore.to_sym, att
    # end
  end

  def log(message)
    @notifier&.ping message
    logger.info message if @debug
  end

  def hud_csv_headers
    self.class.hud_csv_headers
  end

  class_methods do
    def date_provided_column
      nil
    end

    def translate_to_db_headers(row)
      row
    end

    def force_nulls(row)
      row.each do |k, v|
        row[k] = v.presence
      end
    end

    def limit_to_hud_headers(row)
      row.to_h.slice(*hud_csv_headers)
    end

    def clean_row_for_import(row)
      row = force_nulls(row)
      row = limit_to_hud_headers(row)
      # the batch import fails to correctly guess the timezone, force these into useful times
      row[:DateUpdated] = row[:DateUpdated]&.to_time
      row[:DateCreated] = row[:DateCreated]&.to_time
      row[:DateDeleted] = row[:DateDeleted]&.to_time
      row = translate_to_db_headers(row)
      row
    end

    def should_add?(existing)
      existing.to_h.blank?
    end

    def should_restore?(row:, existing:, soft_delete_time:) # rubocop:disable Lint/UnusedMethodArgument
      soft_deleted_this_time = existing.pending_date_deleted.present?
      exists_in_incoming_file = row[:DateDeleted].blank?
      soft_deleted_this_time && exists_in_incoming_file
    end

    def needs_update?(row:, existing:, soft_delete_time: nil) # rubocop:disable Lint/UnusedMethodArgument
      # Incoming is newer
      return false if row[:DateUpdated].blank?

      incoming_newer = row[:DateUpdated].to_time > existing.updated_at
      if incoming_newer
        # puts "incoming newer #{row.inspect} #{existing.updated_at.inspect}"
        return true
      end

      deleted_previously = existing.deleted_at.present?
      exists_in_incoming_file = row[:DateDeleted].blank?
      incoming_updated_on_same_date = row[:DateUpdated].utc.to_date == existing.updated_at.utc.to_date
      # Should be restored
      should_restore = deleted_previously && exists_in_incoming_file && incoming_updated_on_same_date
      if should_restore
        # puts "should restore #{row.inspect} #{existing.updated_at.inspect} #{existing.deleted_at.inspect}"
        return true
      end

      # same modification date, changed data
      data_changed = incoming_updated_on_same_date && row[:source_hash] != existing.source_hash
      if data_changed
        # puts "data changed #{row.inspect} #{existing.inspect}"
        return true
      end

      false
    end

    def delete_involved(projects:, range:, data_source_id:, deleted_at:)
      deleted_count = 0
      # If this is recorded for a specific date, we need to reference
      # that field and only delete those that occurred prior to the ExportEndDate
      projects.each do |project|
        del_scope = joins(enrollment: :project).
          where(Project: { ProjectID: project.ProjectID }, data_source_id: data_source_id).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range))
        del_scope = del_scope.where(arel_table[date_provided_column].lteq(range.end)) if date_provided_column.present?
        deleted_count += del_scope.update_all(pending_date_deleted: deleted_at)
      end
      deleted_count
    end

    def hud_keys_for_batch(rows)
      rows.map do |row|
        row[hud_key]
      end
    end

    def fetch_existing_for_batch(data_source_id:, keys:)
      with_deleted.where(data_source_id: data_source_id).
        where(hud_key => keys).
        pluck(
          hud_key,
          :DateUpdated,
          :DateDeleted,
          :id,
          :source_hash,
          :pending_date_deleted,
          :data_source_id,
        ).map do |key, updated_at, deleted_at, id, source_hash, pending_date_deleted, ds_id| # rubocop:disable Metrics/ParameterLists
          [key, OpenStruct.new(
            updated_at: updated_at,
            deleted_at: deleted_at,
            id: id,
            source_hash: source_hash,
            pending_date_deleted: pending_date_deleted,
            data_source_id: ds_id,
          )]
        end.to_h
    end

    def import_related!(data_source_id:, file_path:, stats:, soft_delete_time:)
      import_file_path = "#{file_path}/#{data_source_id}/#{file_name}"
      return stats unless File.exist?(import_file_path)

      stats[:errors] = []
      headers = nil
      export_id = nil
      File.open(import_file_path) do |file|
        header_row = file.first
        file.lazy.each_slice(10_000) do |lines|
          to_add = []
          to_restore = []
          csv_rows = CSV.parse(lines.join, headers: header_row, header_converters: ->(h) { h.to_sym })
          csv_rows = csv_rows.map do |row|
            clean_row_for_import(row)
          end
          existing_items = fetch_existing_for_batch(
            data_source_id: data_source_id,
            keys: hud_keys_for_batch(csv_rows),
          )
          csv_rows.each do |row|
            export_id ||= row[:ExportID]
            row[:source_hash] = calculate_source_hash(row.except(:ExportID).values)
            existing = existing_items[row[hud_key]]
            # binding.pry if self.name == 'GrdaWarehouse::Import::HMISSixOneOne::Enrollment'
            if should_add?(existing)
              clean_row = row.merge(data_source_id: data_source_id)
              headers ||= clean_row.keys
              to_add << clean_row
            elsif needs_update?(row: row, existing: existing, soft_delete_time: soft_delete_time)
              row[:pending_date_deleted] = nil
              with_deleted.where(id: existing.id).update_all(row)
              stats[:lines_updated] += 1
              stats[:lines_restored] += 1 if existing.pending_date_deleted.present? && row[:DateDeleted].blank?
            elsif should_restore?(row: row, existing: existing, soft_delete_time: soft_delete_time)
              to_restore << existing.id
            end
          end
          # Process the batch
          to_restore.each_slice(1000) do |ids|
            # Make sure to update the export id when restoring to help with service history
            # generation
            with_deleted.where(id: ids).update_all(pending_date_deleted: nil, DateDeleted: nil, ExportID: export_id)
            stats[:lines_restored] += ids.size
          end
          next unless to_add.any?

          to_add = clean_to_add(to_add)
          stats = process_to_add(headers: headers, to_add: to_add, stats: stats)
          log_added(to_add)
        end
      end
      stats
    end

    def calculate_source_hash(values)
      Digest::SHA256.hexdigest string_for_source_hash(values)
    end

    # Since we are using Postgres to calculate these the first time
    # we need to match the postgres format
    def string_for_source_hash(values)
      values.compact.map do |m|
        if m.is_a?(Date)
          m.strftime('%F')
        elsif m.is_a?(Time)
          m.utc.strftime('%F %T')
        else
          m
        end
      end.join(':')
    end

    def pg_source_hash_calculation_query
      columns = (hud_csv_headers - [:ExportID]).map { |m| '"' + m.to_s + '"' }.join(',')
      "UPDATE #{quoted_table_name} SET source_hash = encode(digest(concat_ws(':', #{columns}), 'sha256'), 'hex')"
    end

    def pre_calculate_source_hashes!
      connection.execute pg_source_hash_calculation_query
    end

    def log_added(data)
      return unless should_log?

      headers = to_log.keys + [:imported_at, :type]
      data.each_slice(1000) do |batch|
        insert = batch.map do |row|
          ret = row.values_at(*to_log.values) + [Time.now, name]
          ret if ret.map(&:present?).all?
        end.compact
        new.insert_batch(
          GrdaWarehouse::HudCreateLog,
          headers,
          insert,
        )
      end
    end

    def should_log?
      false
    end

    def process_to_add(headers:, to_add:, stats:)
      to_add.each_slice(200) do |batch|
        new.insert_batch(self, headers, batch.map(&:values), transaction: false)
        stats[:lines_added] += batch.size
      rescue Exception
        message = "Failed to add batch for #{name}, attempting individual inserts"
        stats[:errors] << { message: message, line: '' }
        Rails.logger.warn(message)
        # Try again to add the individual batch
        batch.each do |row|
          create(row)
        rescue Exception => e
          message = "Failed to add #{name}: #{e.message}; giving up on this one."
          stats[:errors] << { message: message, line: row.inspect }
          Rails.logger.warn(message)
        end
      end
      stats
    end

    def clean_to_add(to_add)
      # Remove any duplicates that would violate the unique key constraints
      to_add.index_by { |row| row.values_at(*unique_constraint) }.values
    end

    # Override in sub-classes
    def unique_constraint
      [hud_key, :data_source_id]
    end

    def hud_csv_headers
      @hud_csv_headers
    end

    def setup_hud_column_access(columns)
      @hud_csv_headers = columns
      columns.each do |column|
        alias_attribute(column.to_s.underscore.to_sym, column)
      end
    end
  end
end
