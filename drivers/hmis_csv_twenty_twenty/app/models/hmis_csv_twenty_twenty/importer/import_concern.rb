###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer::ImportConcern
  extend ActiveSupport::Concern
  SELECT_BATCH_SIZE = 10_000
  INSERT_BATCH_SIZE = 2_000
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
    def self.clean_row_for_import(row, deidentified:) # rubocop:disable  Lint/UnusedMethodArgument
      row
    end

    def self.replace_blanks_with_nils(row)
      row.transform_values!(&:presence)
    end

    def self.upsert_column_names(version: '2020')
      super(version: version) - [:pending_date_deleted, :processed_as, :demographic_dirty]
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
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
      involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).with_deleted.
        update_all(pending_date_deleted: pending_date_deleted)
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
      []
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
