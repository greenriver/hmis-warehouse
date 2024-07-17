###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Reads objects from the inbox S3 bucket, processes each CSV file, matches clients to warehouse db, and then writes the results to the outbox S3 bucket.
class IdentifyExternalClientsJob < BaseJob
  # @param inbox_s3 [AwsS3] read from this bucket
  # @param outbox_s3 [AwsS3] write into this bucket
  def perform(inbox_s3:, outbox_s3:)
    with_lock do
      build_lookups
      inbox_s3.list_objects.each do |input_object|
        input_key = input_object.key
        content_type = inbox_s3.get_file_type(key: input_key)
        if content_type.present? && content_type != 'text/csv'
          log("invalid content type #{content_type}", object_key: input_key)
          next
        end

        data_string = inbox_s3.get_as_io(key: input_key)

        input_rows = data_string ? parse_csv_string(data_string, key: input_key) : nil
        if input_rows.blank?
          log('invalid CSV content', object_key: input_key)
          next
        end

        output_rows = input_rows.map { |row| process_row(row) }.compact
        if output_rows.empty?
          log('skipping empty output', object_key: input_key)
          next
        end

        log("matched #{output_rows.size} of #{input_rows.size} rows", type: :info, object_key: input_key)

        # s3.store raises on failure
        outbox_s3.store(
          content: format_as_csv(output_rows.compact),
          name: upload_name(input_key),
          content_type: 'text/csv; charset=utf-8',
        )

        # if we successfully processed the input object, delete it from the bucket
        inbox_s3.delete(key: input_key)
      end
    end
  end

  protected

  def upload_name(filename)
    dir = File.dirname(filename)
    dir = dir == '.' ? nil : dir
    base = File.basename(filename, '.*')
    ext = File.extname(filename)
    [dir, "#{base}-results#{ext}"].compact.join('/')
  end

  private def build_lookups
    @name_lookup = GrdaWarehouse::ClientMatcherLookups::ProperNameLookup.new(transliterate: true)
    @ssn_lookup = GrdaWarehouse::ClientMatcherLookups::SSNLookup.new(format: :last_four)
    @dob_lookup = GrdaWarehouse::ClientMatcherLookups::DOBLookup.new

    clients = GrdaWarehouse::Hud::Client.all
    GrdaWarehouse::ClientMatcherLookups::ClientStub.from_scope(clients) do |client|
      @name_lookup.add(client)
      @ssn_lookup.add(client)
      @dob_lookup.add(client)
    end
  end

  def with_lock(&block)
    GrdaWarehouseBase.with_advisory_lock('identify_external_clients', timeout_seconds: 0, &block)
  end

  def parse_csv_string(csv_string, key:)
    results = []
    begin
      csv = CSV.parse(csv_string, headers: true)
      headers = csv.headers.map { |header| header.strip.downcase }

      results = csv.map do |row|
        # normalize headers
        headers.each_with_object({}) do |header, hash|
          hash[header] = row[header]
        end
      end
    rescue CSV::MalformedCSVError => e
      log("CSV parsing error: #{e.message}", object_key: key)
    rescue ArgumentError => e
      log("Argument error (possibly encoding related): #{e.message}", object_key: key)
    rescue StandardError => e
      log("An unexpected error occurred: #{e.message}", object_key: key)
    end
    results
  end

  def process_row(row)
    first_name, last_name, ssn4, dob, ghocid = row.values_at('first_name', 'last_name', 'ssn4', 'dob', 'ghocid')
    return if ghocid.blank?

    matches = [
      @ssn_lookup.get_ids(ssn: ssn4),
      @dob_lookup.get_ids(dob: dob),
      @name_lookup.get_ids(first_name: first_name, last_name: last_name),
    ]

    match = get_first_match(matches)
    match ? { 'GHOCID' => ghocid, 'Client ID' => match } : nil
  end

  # id is found in at least two match sets
  def get_first_match(matches, required_number: 2)
    count = Hash.new(0)
    matches.each do |match|
      match.each do |id|
        count[id] += 1
        return id if count[id] >= required_number
      end
    end

    nil
  end

  def format_as_csv(rows)
    return if rows.empty?

    headers = rows.first.keys
    CSV.generate do |csv|
      csv << headers
      rows.each do |row|
        csv << headers.map { |header| row[header] }
      end
    end
  end

  def log(message, object_key:, type: :error)
    Rails.logger.send(type, "#{self.class.name} s3:#{object_key}: #{message}")
  end
end
