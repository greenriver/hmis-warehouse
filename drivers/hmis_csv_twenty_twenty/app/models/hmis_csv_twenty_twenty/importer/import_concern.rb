###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer::ImportConcern
  extend ActiveSupport::Concern
  SELECT_BATCH_SIZE = 10_000
  INSERT_BATCH_SIZE = 2_000

  included do
    belongs_to :importer_log

    # Override as necessary
    def self.clean_row_for_import(row, deidentified:) # rubocop:disable  Lint/UnusedMethodArgument
      row
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

    def self.new_from(loaded, deidentified: false)
      # we need to attempt a fix of date columns before ruby auto converts them
      csv_data = loaded.hmis_data
      csv_data = fix_date_columns(csv_data)
      csv_data = fix_time_columns(csv_data)
      csv_data = clean_row_for_import(csv_data, deidentified: deidentified)
      new(csv_data.merge(source_type: loaded.class.name, source_id: loaded.id, data_source_id: loaded.data_source_id))
    end

    # Overide as necessary
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:)
      involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).update_all(pending_date_deleted: pending_date_deleted)
    end

    def self.new_data(data_source_id:, project_ids:, date_range:, importer_log_id:)
      existing_keys = involved_warehouse_scope(
        data_source_id: data_source_id,
        project_ids: project_ids,
        date_range: date_range,
      ).select(hud_key)
      where(importer_log_id: importer_log_id).where.not(hud_key => existing_keys)
    end

    def self.existing_destination_data(data_source_id:, project_ids:, date_range:)
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
      record.source_id = id # Note which record we're sending this from for error checking
      record
    end

    def self.create_columns
      (hmis_structure(version: '2020').keys + [:data_source_id]).map(&:to_s).freeze
    end

    def self.fix_date_columns(row)
      date_columns.each do |col|
        next if row[col].blank? || correct_date_format?(row[col])

        row[col] = fix_date_format(row[col])
      end
      row
    end

    def self.fix_time_columns(row)
      time_columns.each do |col|
        next if row[col].blank? || correct_time_format?(row[col])

        row[col] = fix_time_format(row[col])
      end
      row
    end

    def self.correct_date_format?(string)
      accepted_date_pattern.match?(string)
    end

    def self.accepted_date_pattern
      /\d{4}-\d{2}-\d{2}/.freeze
    end

    def self.correct_time_format?(string)
      accepted_time_pattern.match?(string)
    end

    def self.accepted_time_pattern
      @accepted_time_pattern ||= /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/.freeze
    end

    # We sometimes see very odd dates, this will attempt to make them sane.
    # Since most dates should be not too far in the future, we'll check for anything less
    # Than a year out
    def self.fix_date_format(string)
      return unless string
      # Ruby handles yyyy-m-d just fine, so we'll allow that even though it doesn't match the spec
      return string if /\d{4}-\d{1,2}-\d{1,2}/.match?(string)

      # Sometimes dates come in mm-dd-yyyy and Ruby Date really doesn't like that.
      if /\d{1,2}-\d{1,2}-\d{4}/.match?(string)
        month, day, year = string.split('-')
        return "#{year}-#{month}-#{day}"
      end
      # NOTE: by default ruby converts 2 digit years between 00 and 68 by adding 2000, 69-99 by adding 1900.
      # https://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
      # Since we're almost always dealing with dates that are in the past
      # If the year is between 00 and next year, we'll add 2000,
      # otherwise, we'll add 1900
      @next_year ||= Date.current.next_year.strftime('%y').to_i
      begin
        d = Date.parse(string, false) # false to not guess at century
      rescue ArgumentError
        return
      end
      if d.year <= @next_year
        d = d.next_year(2000)
      else
        d = d.next_year(1900)
      end
      d.strftime('%Y-%m-%d')
    end

    def self.fix_time_format(string)
      return unless string
      # Ruby handles yyyy-m-d just fine, so we'll allow that even though it doesn't match the spec
      return string if /\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:?\d{0,2}?/.match?(string)

      # Sometimes times come in mm/dd/yyyy hh:mm
      if /\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{1,2}:?\d{0,2}?/.match?(string) # rubocop:disable Style/RegexpLiteral
        date, time = string.split(' ')
        month, day, year = date.split('/')
        return "#{year}-#{month}-#{day} #{time}"
      end
      # NOTE: by default ruby converts 2 digit years between 00 and 68 by adding 2000, 69-99 by adding 1900.
      # https://pubs.opengroup.org/onlinepubs/009695399/functions/strptime.html
      # Since we're almost always dealing with dates that are in the past
      # If the year is between 00 and next year, we'll add 2000,
      # otherwise, we'll add 1900
      @next_year ||= Date.current.next_year.strftime('%y').to_i
      d = DateTime.parse(string, false) # false to not guess at century
      if d.year <= @next_year
        d = d.next_year(2000)
      else
        d = d.next_year(1900)
      end
      d.strftime('%Y-%m-%d %H%M%S')
    end

    def self.hmis_validations
      []
    end

    def calculate_source_hash
      keys = self.class.hmis_structure(version: '2020').keys - [:ExportID]
      Digest::SHA256.hexdigest(slice(keys).to_s)
    end

    # NOTE: this may be way faster, but would need to be done as a second step
    # def pg_source_hash_calculation_query
    #   columns = (hud_csv_headers - [:ExportID]).map { |m| '"' + m.to_s + '"' }.join(',')
    #   "UPDATE #{quoted_table_name} SET source_hash = encode(digest(concat_ws(':', #{columns}), 'sha256'), 'hex')"
    # end

    def set_source_hash
      self.source_hash = calculate_source_hash
    end

    def run_row_validations
      failures = []
      self.class.hmis_validations.each do |column, checks|
        next unless checks.present?

        checks.each do |check|
          arguments = check.dig(:arguments)
          failures << check[:class].check_validity!(self, column, arguments)
        end
      end
      failures.compact
    end
  end
end
