###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisSupplemental::ImportJob < BaseJob
  attr_reader :data_set

  # csv_string is mostly for QA
  def perform(data_set_id:, csv_string: nil)
    @data_set = HmisSupplemental::DataSet.where(id: data_set_id).first
    return unless @data_set

    csv_string ||= read_csv_from_s3

    with_lock do
      values = read_csv_rows(csv_string).
        flat_map { |row| row_values(row) }.
        compact

      if values.empty?
        log('Could not map custom data elements from CSV')
        return
      end

      values = deduplicate_rows(values)
      data_set.transaction do
        # Delete and recreate. This could be an upsert
        data_set.field_values.delete_all(:delete_all)
        HmisSupplemental::FieldValue.import!(values, validate: false)
      end
    end
  end

  protected

  def object_key
    data_set.full_object_key
  end

  def read_csv_from_s3
    s3 = data_set.remote_credential.s3
    s3.get_as_io(key: object_key).read
  end

  def read_csv_rows(csv_string)
    rows = nil
    begin
      rows = parse_csv_string(csv_string)
    rescue CSV::MalformedCSVError => e
      log("CSV parsing error: #{e.message}")
    rescue ArgumentError => e
      log("Argument error (possibly encoding related): #{e.message}")
    rescue StandardError => e
      log("An unexpected error occurred: #{e.message}")
    end

    rows || []
  end

  # consolidate multi-valued rows; otherwise use the first value
  def deduplicate_rows(rows)
    results = {}

    fields = data_set.fields.index_by(&:key)
    rows.each do |row|
      field_key = row.fetch(:field_key)
      field = fields.fetch(field_key)
      row_key = "#{field_key}|#{row.fetch(:owner_key)}"

      result = results[row_key]
      if result
        next unless field.multi_valued

        result[:data] = Array(result[:data]) + Array(row[:data])
      else
        results[row_key] = row
      end
    end

    results.values
  end

  def row_values(row)
    data_set.fields.map do |field|
      data = field.row_value_data(row)
      next if data.nil?

      owner_key = field.row_owner_key(row)

      if owner_key.nil?
        log("could not find owner in CSV, line #{row[:row_number]}")
        next
      end

      {
        owner_key: owner_key,
        field_key: field.key,
        data: data,
        data_set_id: data_set.id,
      }
    end
  end

  def with_lock(&block)
    lock_name = "#{self.class.name}:#{data_set.id}"
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end

  def log(message, type: :error)
    Rails.logger.send(type, "#{self.class.name} s3:#{object_key}: #{message}")
    nil
  end

  def parse_csv_string(csv_string)
    csv = CSV.parse(csv_string, headers: true)
    results = csv.map.with_index(1) do |row, row_number|
      new_row = {}
      # normalize headers
      csv.headers.each do |header|
        new_row[header.downcase] = row[header]&.strip.presence
      end
      next if new_row.empty?

      new_row[:row_number] = row_number
      new_row
    end
    results.compact
  end
end
