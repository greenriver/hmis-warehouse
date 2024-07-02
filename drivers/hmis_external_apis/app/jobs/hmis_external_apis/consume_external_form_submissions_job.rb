###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# retrieve and process external form submissions
class HmisExternalApis::ConsumeExternalFormSubmissionsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  def perform
    s3 = GrdaWarehouse::RemoteCredentials::S3.for_active_slug('hmis_external_form_submissions')&.s3
    encryption_key = GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey.for_active_slug('hmis_external_forms_shared_key')

    return unless s3 && encryption_key

    s3.list_objects.each do |object|
      raw_data_string = s3.get_as_io(key: object.key)&.read
      raw_data = raw_data_string ? parse_json(raw_data_string) : nil
      if !raw_data
        log_error('invalid JSON content', object_key: object.key)
        next
      end

      submission = submission_class.transaction do
        process_submission(raw_data, object, encryption_key: encryption_key)
      end
      # if we successfully processed the submission, delete it
      s3.delete(key: object.key) if submission
    end
  end

  protected

  def log_error(message, object_key:)
    Rails.logger.error("external form submission #{object_key}: #{message}")
  end

  def process_submission(raw_data, object, encryption_key:)
    definition_id = begin
      raw_data['form_definition_id'].presence&.then { |value| ProtectedId::Encoder.decode(value) }
    rescue OpenSSL::Cipher::CipherError => e
      log_error("form id decode failed: #{e.message}", object_key: object.key)
    end
    if definition_id.nil?
      log_error('missing definition_id', object_key: object.key)
      return nil
    end

    definition = Hmis::Form::Definition.where(id: definition_id).first
    if definition.nil?
      log_error("unknown definition_id: #{definition_id}", object_key: object.key)
      return nil
    end

    spam_score = begin
      encryption_key.decrypt(raw_data['captcha_score'])&.to_f
    rescue StandardError => e
      log_error("decryption failed #{e.message}", object_key: object.key)
      nil
    end

    submission = submission_class.from_raw_data(
      raw_data,
      object_key: object.key,
      last_modified: object.last_modified,
      spam_score: spam_score,
      form_definition: definition,
    )
    submission
  end

  def submission_class
    HmisExternalApis::ExternalForms::FormSubmission
  end

  # str should be a json document but it is user supplied and could be anything
  def parse_json(str)
    # some preflight sanity checks before we parse
    return nil unless str.present? && str[0] == '{' && str[-1] == '}' && str.size <= 100_000

    JSON.parse(str)
  rescue JSON::ParserError
    nil
  end
end
