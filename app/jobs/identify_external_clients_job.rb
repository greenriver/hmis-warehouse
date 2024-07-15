
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class IdentifyExternalClientsJob < BaseJob
  def perform(inbox_s3_slug:, outbox_s3_slug:)
    inbox_s3 = s3_for_slug(inbox_s3_slug)
    outbox_s3 = s3_for_slug(inbox_s3_slug)
    return unless inbox_s3 && outbox_s3

    with_lock do
      inbox_s3.list_objects.each do |input_object|
        input_key = input_object.key
        raw_input = inpbox_s3.get_as_io(key: input_key)&.read
        output_csv = process_input(raw_input)

        # if we successfully processed the input object, delete it from the bucket
        output_object = upload_to_s3(outbox_s3, output_csv, key: "#{input_key}_results.csv")
        if output_object
          s3.delete(key: input_key)
        else
          log('failed to upload output', object_key: input_key)
        end
      end
    end
  end

  protected

  def upload_to_s3(s3, output_csv, key: "#{input_key}_results.csv")
    return if Rails.env.development? || Rails.env.test?

    # use bucket/object rather than AwsS3 methods here since we want to publish the form without access restrictions.
    # Maybe this could be DRYed up in the future if we find more use cases
    object = s3.bucket.object(publication.object_key)
    object.put(body: publication.content, content_type: 'text/csv; charset=utf-8')
  end

  def s3_for_slug(slug)
    GrdaWarehouse::RemoteCredentials::S3.for_active_slug(slug)&.s3
  end

  def process_input(raw_input)
    input_rows = raw_input ? process_csv_string(raw_input) : nil
    if input_rows.empty?
      log('invalid CSV content', object_key: object.key)
      return
    end

    output_rows = input_rows.map do |row|
      process_rows(input_row)
    end
    output_csv = format_as_csv(output_rows)

  end

  def with_lock(&block)
    GrdaWarehouseBase.with_advisory_lock('identify_external_clients', timeout_seconds: 0, &block)
  end

  def process_csv_string(csv_string)
    csv = CSV.parse(csv_string, headers: true)
    headers = csv.headers.map { |header| header.strip.downcase }

    csv.map do |row|
      # normalize headers
      headers.each_with_object({}) do |header, hash|
        hash[header] = row[header]
      end
    end
  end

  def process_row(row)
    client_lookup.check_for_obvious_match(client_id)
    first_name, last_name, ssn4, dob = row.values_at(:first_name, :last_name :ssn4, :dob, :ghocid)

    matches = [
      basic_client_matcher.check_social(ssn: ssn4),
      basic_client_matcher.check_birthday(dob: dob),
      basic_client_matcher.check_name(first_name: first_name, last_name: last_name),
    ]

    match = get_first_match(matches)
    [ghocid, match]
  end

  # If no integer is found in at least two arrays
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

  def client_lookup
    @client_lookup.GrdaWarehouse::ClientBasicMatcher
  end

  def upload_to_s3(output_csv)
    raise
  end

  def log(message, object_key:, type: :error)
    Rails.logger.send(type, "#{class.name} s3:#{object_key}: #{message}")
  end
end
