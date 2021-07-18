###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer::ImportConcern
  extend ActiveSupport::Concern
  SELECT_BATCH_SIZE = 10_000
  INSERT_BATCH_SIZE = 5_000
  RE_YYYYMMDD = /(?<y>\d{4})-(?<m>\d{1,2})-(?<d>\d{1,2})/.freeze

  HMIS_DATE_FORMATS = [
    ['%Y-%m-%d', RE_YYYYMMDD],
    ['%m-%d-%Y'],
    ['%d-%b-%Y'],
  ].freeze

  HMIS_TIME_FORMATS = ([
    ['%Y-%m-%d %H:%M:%S', RE_YYYYMMDD],
    ['%m-%d-%Y %H:%M:%S'],
    ['%d-%b-%Y %H:%M:%S'],
    ['%Y-%m-%d %H:%M', RE_YYYYMMDD],
    ['%m-%d-%Y %H:%M'],
    ['%d-%b-%Y %H:%M'],
  ] + HMIS_DATE_FORMATS).freeze # order matters, we need to try more logical and longer patterns first

  included do
    belongs_to :importer_log
    has_many :involved_in_imports, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :record
    # has_many :involved_in_import_updates, do
    #   where(record_action: :updated)
    # end, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :record, primary_key: [hud_key, :import_log_id,
    #     importer_log_id: importer_log_id,
    #     hud_key => HmisCsvTwentyTwenty::Importer::InvolvedInImport.
    #       where(
    #         importer_log_id: importer_log_id,
    #         record_action: :updated,
    #       ).select(:hud_key),
    #   )

    # If the model is paranoid, include the deleted rows by default
    default_scope do
      if paranoid?
        with_deleted
      else
        all
      end
    end

    scope :should_import, -> do
      where(should_import: true)
    end

    # Override as necessary
    def self.clean_row_for_import(row, deidentified:) # rubocop:disable Lint/UnusedMethodArgument
      row
    end

    def self.replace_blanks_with_nils(row)
      row.transform_values!(&:presence)
    end

    def self.upsert_column_names(version: '2020')
      super(version: version) - [:processed_as, :demographic_dirty]
    end

    def self.upsert?
      false
    end

    def self.date_columns
      hmis_columns = hmis_structure(version: '2020').keys
      content_columns.select do |c|
        c.type == :date && c.name.to_sym.in?(hmis_columns)
      end.map do |c|
        c.name.to_s
      end
    end
    # memoize :date_columns

    def self.time_columns
      hmis_columns = hmis_structure(version: '2020').keys
      content_columns.select do |c|
        c.type == :datetime && c.name.to_sym.in?(hmis_columns)
      end.map do |c|
        c.name.to_s
      end
    end
    # memoize :time_columns

    def self.attrs_from(loaded, deidentified: false)
      # we need to attempt a fix of date columns before ruby auto converts them
      csv_data = loaded.hmis_data
      csv_data = fix_date_columns(csv_data)
      csv_data = fix_time_columns(csv_data)
      csv_data = clean_row_for_import(csv_data, deidentified: deidentified)
      csv_data = replace_blanks_with_nils(csv_data)
      csv_data.merge(
        source_type: loaded.class.name,
        source_id: loaded.id,
        data_source_id: loaded.data_source_id,
      )
    end

    def self.new_from(loaded, deidentified: false)
      new attrs_from(loaded, deidentified: deidentified)
    end

    # Override as necessary
    # def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:, importer_log_id:)
    #   involved_warehouse_scope(
    #     data_source_id: data_source_id,
    #     project_ids: project_ids,
    #     date_range: date_range,
    #   ).with_deleted.
    #     # Exclude records that are unchanged
    #     joins(Arel.sql(left_join_non_matching_import_to_warehouse_sql(importer_log_id))).
    #     where(arel_table[:importer_log_id].eq(nil)).
    #     update_all(pending_date_deleted: pending_date_deleted)
    # end

    def self.plan_ingest(data_source_id:, project_ids:, date_range:, pending_date_deleted:, importer_log_id:) # rubocop:disable Lint/UnusedMethodArgument
      involved = []
      # In an attempt to keep RAM usage way down, we'll use some positional data
      import_order = [
        :importer_log_id,
        :record_id,
        :record_type,
        :record_action,
        :hud_key,
      ]
      pluck_columns = [
        hud_key,
        :id,
        :source_hash,
        :DateUpdated,
      ]
      import_scope = where(importer_log_id: importer_log_id)

      # If this is the Export table, just add the row, there will always be one
      if hud_key == :ExportID
        (_, id,) = import_scope.pluck(hud_key, :id).first
        involved << [
          importer_log_id,
          id,
          name,
          :add,
          key,
        ]
      else
        import_scope = import_scope.with_deleted if paranoid?
        import_data = import_scope.pluck(pluck_columns).index_by(&:first)

        existing_data = involved_warehouse_scope(
          data_source_id: data_source_id,
          project_ids: project_ids,
          date_range: date_range,
        ).with_deleted.
          pluck(pluck_columns).index_by(&:first)

        to_add = import_data.keys - existing_data.keys
        to_add.each do |key|
          (_, id,) = import_data[key]
          involved << [
            importer_log_id,
            id,
            name,
            :add,
            key,
          ]
        end

        to_remove = existing_data.keys - import_data.keys
        to_remove.each do |key|
          (_, id,) = existing_data[key]
          involved << [
            importer_log_id,
            id,
            warehouse_class.name,
            :needs_removal,
            key,
          ]
          to_remove.delete(key)
        end

        existing_data.each do |key, (_, existing_id, source_hash, updated_at)|
          (_, _, import_source_hash, import_updated_at) = import_data[key]
          record_action = if source_hash == import_source_hash
            :unchanged
          elsif updated_at.to_date > import_updated_at.to_date
            :needs_update
          end
          involved << [
            importer_log_id,
            existing_id,
            warehouse_class.name,
            record_action,
            key,
          ]
        end
      end
      HmisCsvTwentyTwenty::Importer::InvolvedInImport.import(import_order, involved)
    end

    # Just update the ExportID
    # Returns number unchanged
    def self.unchanged(importer_log_id:, data_source_id:, export_id:)
      warehouse_class.where(data_source_id: data_source_id).
        joins(:involved_in_imports).
        merge(
          HmisCsvTwentyTwenty::Importer::InvolvedInImport.
            where(
              importer_log_id: importer_log_id,
              record_action: :unchanged,
            ),
        ).update_all(ExportID: export_id)
    end

    # Create new records for records not seen before
    def self.added(importer_log_id:, data_source_id:, export_id:) # rubocop:disable Lint/UnusedMethodArgument
      batch = []
      total_changed = 0
      where(importer_log_id: importer_log_id).
        joins(:involved_in_imports).
        merge(
          HmisCsvTwentyTwenty::Importer::InvolvedInImport.
            where(
              importer_log_id: importer_log_id,
              record_action: :added,
            ),
        ).find_each(batch_size: SELECT_BATCH_SIZE) do |row|
          batch << row.as_destination_record
          if batch.count == INSERT_BATCH_SIZE
            total_changed += batch.count
            columns = batch.first.attributes.keys - ['id']
            warehouse_class.import(
              batch,
              import_options(columns),
            )
            batch = []
          end
        end

      # Make sure we don't leave any behind
      if batch.count.positive?
        total_changed += batch.count
        columns = batch.first.attributes.keys - ['id']
        warehouse_class.import(
          batch,
          import_options(columns),
        )
        batch = []
      end
      total_changed
    end

    # Copy from the import tables to the warehouse using an upsert
    def self.updated(importer_log_id:, data_source_id:, export_id:) # rubocop:disable Lint/UnusedMethodArgument
      columns = upsert_column_names
      batch = []
      total_changed = 0
      involved_table_name = HmisCsvTwentyTwenty::Importer::InvolvedInImport.quoted_table_name
      join_sql = <<-SQL.squish
        inner join #{involved_table_name}
        on #{involved_table_name}.hud_key = #{quoted_table_name}.#{connection.quote_column_name(hud_key)}
        and #{involved_table_name}.importer_log_id = #{quoted_table_name}.importer_log_id
      SQL
      joins(join_sql)
      where(importer_log_id: importer_log_id).
        merge(HmisCsvTwentyTwenty::Importer::InvolvedInImport.where(record_action: :updated)).
        find_each(batch_size: SELECT_BATCH_SIZE) do |row|
          batch << row.as_destination_record
          if batch.count == INSERT_BATCH_SIZE
            # Client model doesn't have a uniqueness constraint because of the warehouse data source
            # so these must be processed more slowly
            if hud_key == :PersonalID
              batch.each do |incoming|
                warehouse_class.where(
                  data_source_id: data_source_id,
                  PersonalID: incoming.PersonalID,
                ).with_deleted.update_all(incoming.slice(upsert_column_names))
              end
            else
              warehouse_class.import(
                batch,
                import_options(columns),
              )
            end
            total_changed += batch.count
            batch = []
          end
        end

      # Make sure we don't leave any behind
      if batch.count.positive?
        if hud_key == :PersonalID
          batch.each do |incoming|
            warehouse_class.where(
              data_source_id: data_source_id,
              PersonalID: incoming.PersonalID,
            ).with_deleted.update_all(incoming.slice(upsert_column_names))
          end
        else
          warehouse_class.import(
            batch,
            import_options(columns),
          )
        end
        total_changed += batch.count
        batch = []
      end
      total_changed
    end

    # Remove from warehouse
    # Returns number removed
    def self.removed(importer_log_id:, data_source_id:, export_id:) # rubocop:disable Lint/UnusedMethodArgument
      warehouse_class.where(data_source_id: data_source_id).
        joins(:involved_in_imports).
        merge(
          HmisCsvTwentyTwenty::Importer::InvolvedInImport.
            where(
              importer_log_id: importer_log_id,
              record_action: :removed,
            ),
        ).update_all(DateDeleted: Date.current)
    end

    def self.un_updateable_warehouse_classes
      [
        'GrdaWarehouse::Hud::Export',
        'GrdaWarehouse::Hud::Client',
      ].freeze
    end

    # NOTE: we are allowing upserts to handle the situation where data is in the warehouse with a HUD key that
    # for whatever reason doesn't fall within the involved scope
    # also NOTE: if aggregation is used, the count of added Enrollments and Exits will reflect the
    # entire history of enrollments for aggregated projects because some of the existing enrollments fall
    # outside of the range, but are necessary to calculate the correctly aggregated set
    def self.import_options(columns)
      options = { validate: false }
      return options if warehouse_class.name.in?(un_updateable_warehouse_classes)

      options.merge(
        on_duplicate_key_update: {
          conflict_target: warehouse_class.conflict_target,
          columns: columns,
        },
      )
    end

    def self.left_join_non_matching_import_to_warehouse_sql(importer_log_id)
      warehouse_table_name = warehouse_class.quoted_table_name
      import_table_name = quoted_table_name
      <<-SQL.squish
        left outer join #{import_table_name}
        on #{warehouse_table_name}.data_source_id = #{import_table_name}.data_source_id
        and #{warehouse_table_name}.#{connection.quote_column_name(hud_key)} = #{import_table_name}.#{connection.quote_column_name(hud_key)}
        and #{warehouse_table_name}.source_hash = #{import_table_name}.source_hash
        and #{import_table_name}.importer_log_id = #{importer_log_id}
      SQL
    end

    def self.new_data(data_source_id:, project_ids:, date_range:, importer_log_id:)
      existing_keys = involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).select(hud_key)
      existing_keys = existing_keys.with_deleted if paranoid?

      where(importer_log_id: importer_log_id).should_import.where.not(hud_key => existing_keys)
    end

    def self.existing_data(data_source_id:, project_ids:, date_range:)
      existing_scope = involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      )
      existing_scope = existing_scope.with_deleted if paranoid?
      existing_scope
    end

    def self.incoming_data(importer_log_id:)
      where(importer_log_id: importer_log_id).should_import
    end

    def self.existing_destination_data(data_source_id:, project_ids:, date_range:)
      involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).with_deleted.
        delete_pending
    end

    def self.pending_deletions(data_source_id:, project_ids:, date_range:)
      involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).delete_pending
    end

    def as_destination_record
      # For some odd reason calling build_destination_record sometimes does a find and update
      # using new seems safer
      klass = self.class.reflect_on_association(:destination_record).klass
      record = klass.new(
        attributes.slice(*self.class.create_columns),
      )
      record.source_hash = source_hash
      # Note which record we're sending this from for error checking
      record.source_id = id
      # If we're creating a new record from a previously deleted
      # record, make sure we bring it back to life
      record.DateDeleted = self.DateDeleted if klass.paranoid?
      record
    end

    def self.create_columns
      (hmis_structure(version: '2020').keys + [:data_source_id]).map(&:to_s).freeze
    end

    def self.fix_date_columns(row)
      date_columns.each do |col|
        row[col] = fix_date_format(row[col])
      end
      row
    end

    def self.fix_time_columns(row)
      time_columns.each do |col|
        row[col] = fix_time_format(row[col])
      end
      row
    end

    # HMIS CSV FORMAT SPECIFICATIONS says under "Data Types"
    # https://hudhdx.info/Resources/Vendors/HMIS%20CSV%20Specifications%20FY2020%20v1.8.pdf
    #
    # Date fields must be in the format yyyy-mm-dd
    # Datetime aka T fields must be in the format yyyy-mm-dd hh:mm:ss with no reference to timezones.
    #
    # In practice HMIS systems send us data in a local timezone and
    # we run their instance in the same timezone but we currently
    # store data in a postgres timestamp column in the databases configured
    # timezone. Be default this is UTC. Rails can handle the timezone math for
    # us as long as we are passing around ActiveSupport::TimeWithZone objects
    # so this method is careful to generate those assuming we are in
    # Time.zone  (the configured timezone for Rails)
    #
    # We also need to handle non-compliant data sources as best we can
    # so we also test for and recognize other common date formats in the US
    # and handle 2-digit years. Nearly all dates in HMIS are in the past or
    # current year so we choose an interpretation of a 2 digit year
    # in that range on import if we have to.

    def self.fix_date_format(string)
      result = fix_time_format(string, formats: HMIS_DATE_FORMATS)
      result = result.strftime('%F') if result.respond_to?(:strftime)
      result
    end

    def self.fix_time_format(string, formats: HMIS_TIME_FORMATS)
      return string if string.blank?
      return string if string.acts_like?(:time)

      # We don't care if we have slashes or hyphens
      normalized = string.tr('/', '-')

      # try various pattern, starting with the standard
      t = nil
      formats.detect do |strptime_pattern, regexp_filter|
        # puts "#{string} #{normalized} #{strptime_pattern} #{regexp_filter}"
        next if regexp_filter && !normalized.match?(regexp_filter)

        t ||= begin
                Time.zone.strptime(normalized, strptime_pattern)
              rescue StandardError
                nil
              end
      end

      return unless t

      if t.year < 100
        # We will choose between 19XX and 20XX based on the idea
        # that our dates are most likely to be in the recent past and not
        # to far into the future
        next_year = Date.current.next_year.year % 100
        if t.year <= next_year # a two digit year we think is in this century
          t = t.change(year: t.year + 2000)
        else
          # a two digit year we think is in the prior century
          t = t.change(year: t.year + 1900)
        end
      end

      t
    end

    def self.hmis_validations
      []
    end

    def self.complex_validations
      [
        {
          class: HmisCsvValidation::UniqueHudKey,
        },
      ]
    end

    def self.hmis_2020_keys
      @hmis_2020_keys ||= hmis_structure(version: '2020').keys
    end

    def hmis_data
      slice(*self.class.hmis_2020_keys) # self.class.hmis_2020_keys is used to avoid realloc/calc'ing these static keys in tight import loops
    end

    def calculate_source_hash
      Digest::SHA256.hexdigest(hmis_data.except(:ExportID).to_s)
    end

    # NOTE: this may be way faster, but would need to be done as a second step
    # def pg_source_hash_calculation_query
    #   columns = (hud_csv_headers - [:ExportID]).map { |m| '"' + m.to_s + '"' }.join(',')
    #   "UPDATE #{quoted_table_name} SET source_hash = encode(digest(concat_ws(':', #{columns}), 'sha256'), 'hex')"
    # end

    def set_source_hash
      self.source_hash = calculate_source_hash
    end

    def self.run_complex_validations!(importer_log, filename)
      failures = []
      complex_validations.each do |check|
        logger.debug { "Running #{check[:class]} for #{self}" }
        arguments = check.dig(:arguments)
        failures += check[:class].check_validity!(self, importer_log, arguments)
      end
      failures.compact!
      importer_log.summary[filename]['total_flags'] ||= 0
      importer_log.summary[filename]['total_flags'] += failures.count
      failures
    end
  end
end
