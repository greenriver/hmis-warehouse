###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Reads objects from the inbox S3 bucket, processes each CSV file, matches clients to warehouse db, and then writes the results to the outbox S3 bucket.
class IdentifyExternalClientsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  # Setup looks something like:
  # GrdaWarehouse::RemoteCredential::S3.create(
  #   username: 'unknown',
  #   password: 'unknown',
  #   slug: 'identify_external_clients',
  #   bucket: 'bucket-name',
  #   path: 'analytic-store/unprocessed',
  #   endpoint: 'analytic-store/processed',
  #   additional_headers: { 'external_id_field' => 'external_client_id' },
  # )
  def self.run_all!
    GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'identify_external_clients').each do |cred|
      s3 = AwsS3.new(bucket_name: cred.bucket)
      inbox_path = cred.path
      outbox_path = cred.endpoint
      external_id_field = cred.additional_headers['external_id_field']
      IdentifyExternalClientsJob.new(s3: s3, inbox_path: inbox_path, outbox_path: outbox_path, external_id_field: external_id_field).perform_now
    end
  end

  # @param s3 [AwsS3] read and write to this bucket
  # @param inbox_path [String] read from this path
  # @param outbox_path [String] write into this path
  # @param external_id_field [String] field to return in the results
  def perform(s3:, inbox_path:, outbox_path:, external_id_field:)
    with_lock do
      build_lookups
      s3.list_objects(prefix: inbox_path).each do |input_object|
        input_key = input_object.key

        data_string = s3.get_as_io(key: input_key)&.read

        content_type = FileMagic.new(FileMagic::MAGIC_MIME_TYPE).buffer(data_string)
        if content_type != 'text/csv'
          log("invalid content type #{content_type}", object_key: input_key)
          next
        end

        input_rows = data_string ? parse_csv_string(data_string, key: input_key) : nil
        if input_rows.blank?
          log('invalid CSV content', object_key: input_key, crash: true)
          next
        end

        output_rows = input_rows.map { |row| process_row(row, external_id_field) }.compact
        log('no matching rows found', object_key: input_key) if output_rows.empty?

        log("matched #{output_rows.size} of #{input_rows.size} rows", type: :info, object_key: input_key)

        # s3.store raises on failure
        s3.store(
          content: format_as_csv(output_rows.compact, external_id_field),
          name: upload_name(input_key, prefix: outbox_path),
          content_type: 'text/csv; charset=utf-8',
        )

        # if we successfully processed the input object, delete it from the bucket
        s3.delete(key: input_key)
      end
    end
  end

  protected

  def upload_name(filename, prefix: nil)
    base = File.basename(filename, '.*')
    ext = File.extname(filename)
    [prefix, "#{base}-results#{ext}"].compact.join('/')
  end

  private def build_lookups
    @name_lookup = GrdaWarehouse::ClientMatcherLookups::ProperNameLookup.new(transliterate: true)
    @ssn_lookup = GrdaWarehouse::ClientMatcherLookups::SSNLookup.new(format: :last_four)
    @dob_lookup = GrdaWarehouse::ClientMatcherLookups::DOBLookup.new

    clients = GrdaWarehouse::Hud::Client.joins(:warehouse_client_source).source
    wc_t = GrdaWarehouse::WarehouseClient.arel_table
    id_field = Arel.sql(wc_t[:destination_id].to_sql)
    GrdaWarehouse::ClientMatcherLookups::ClientStub.from_scope(clients, id_field: id_field) do |client|
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
      results = csv.map do |row|
        # normalize headers
        csv.headers.each_with_object({}) do |header, hash|
          hash[header.downcase] = row[header]
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

  def process_row(row, external_id_field)
    first_name, last_name, ssn4, dob, external_id = row.values_at('first_name', 'last_name', 'ssn4', 'dob', external_id_field.downcase)
    return if external_id.blank?

    matches = [
      @ssn_lookup.get_ids(ssn: ssn4.to_s),
      @dob_lookup.get_ids(dob: dob&.to_date),
      @name_lookup.get_ids(first_name: first_name.to_s, last_name: last_name.to_s),
    ]

    match = get_best_match(matches)
    match ? { external_id_field => external_id, 'Client ID' => match } : nil
  end

  # matching id is found in at least two match sets
  def get_best_match(match_sets, min_rank: 2)
    ranks = match_sets.flatten.tally

    best_match = nil
    max_rank = match_sets.size
    ranks.keys.sort.each do |match|
      rank = ranks[match]
      # this is below the rank we should consider
      next if rank < min_rank

      # this our new best_match
      best_match = match if best_match.nil? || rank > ranks[best_match]
      # short circuit and return if this is at max rank
      break if rank == max_rank
    end
    best_match
  end

  def format_as_csv(rows, external_id_field)
    headers = rows&.first&.keys || [external_id_field, 'Client ID']
    CSV.generate do |csv|
      csv << headers
      rows&.each do |row|
        csv << headers.map { |header| row[header] }
      end
    end
  end

  def log(message, object_key:, type: :error, crash: false)
    Rails.logger.send(type, "#{self.class.name} s3:#{object_key}: #{message}")
    return unless crash

    Sentry.capture_exception_with_info(
      StandardError.new(message),
      info: { object_key: object_key },
    )
  end
end
