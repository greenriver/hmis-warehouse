
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class IdentifyExternalClientsJob < BaseJob
  #include NotifierConfig

  def perform(s3_slug:)
    s3 = GrdaWarehouse::RemoteCredentials::S3.for_active_slug(s3_slug)&.s3
    return unless s3

    with_lock do
      s3.list_objects.each do |object|
        handle_object(object)
      end
    end
  end

  protected

  def handle_object(object)
    raw_input = s3.get_as_io(key: object.key)&.read
    input_rows = raw_input ? process_csv_string(raw_input) : nil
    if input_rows.blank?
      log('invalid CSV content', object_key: object.key)
      return
    end

    output_csv = process_rows(input_rows)

    # if we successfully processed the submission, delete it
    output_object =  upload_to_s3(output_csv)
    if output_object
      s3.delete(key: object.key)
    else
      log('failed to upload output', object_key: object.key)
    end
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

  def process_rows(rows)
    rows.each do |row|
      client_lookup.check_for_obvious_match(client_id)
      first_name, last_name ssn4, dob, hmis_id, ghocid = row.values_at(:first_name, :last_name :ssn4, :dob, :hmis_id, :ghocid)

      ssn_matches = basic_client_matcher.check_social(ssn: ssn4)
      birthdate_matches = basic_client_matcher.check_birthday(dob: dob)
      name_matches = basic_client_matcher.check_name(first_name: first_name, last_name: last_name)

      all_matches = ssn_matches + birthdate_matches + name_matches
      obvious_matches.compact!

      return obvious_matches.first if obvious_matches.any?

      return nil

    end
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
