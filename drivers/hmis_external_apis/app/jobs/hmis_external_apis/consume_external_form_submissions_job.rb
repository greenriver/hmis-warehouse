###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# retrieve and process external form submissions
class HmisExternalApis::ConsumeExternalFormSubmissionsJob
  def perform
    s3.list_objects.each do |object|
      raw_data = s3.get_as_io(key: object.key)&.read
      submission_data = parse_json(raw_data)
      if !submission_data
        logger_error('invalid JSON content', object_key: object.key)
        next
      end

      submission = submission_class.transaction do
        process_submission(submission_data, object)
      end
      # if we successfully processed the submission, delete it
      s3.delete(key: object.key) if submission
    end
  end

  protected

  def log_error(message, object_key:)
    Rails.logger.error("external form submission #{object_key}: #{message}")
  end

  def process_submission(submission_data, object)
    definition_id = submission_data['form_definition_id'].
      presence&.then { |value| ProtectedId::Encoder.decode(value) }
    if definition_id.nil?
      Rails.logger.error("external form submission #{object.key}: missing definition_id")
      logger_error('missing definition_id', object_key: object.key)
      return nil
    end

    spam_score = submission_data['spam_score'].presence&.to_i

    # there might be a submission already if we processed it but didn't delete it from s3
    submission = submission_class.where(object_key: object.key).first_or_initialize
    submission.status ||= 'new'

    submission.attributes = {
      submitted_at: object.last_modified,
      spam_score: spam_score,
      form_definition_id: definition_id,
      submission_data: submission_data,
    }
    submission.save!
    build_cdes(definition, submission)

    submission
  end

  # extract the and build custom data elements from the payload
  def build_cdes(definition, submission)
    submission.custom_data_elements.delete_all
    owner_type = definition.external_form_submission_data_element_owner_type
    cdes = []
    Hmis::Hud::CustomDataElementDefinition.for_type(owner_type).each do |cded|
      value = submission.raw_data[cded.key]
      next if value.blank?

      cdes << {
        owner_type: submission.class.sti_name,
        owner_id: submission.id,
        value_string: value,
        data_source_id: cded.data_source_id,
        data_element_definition_id: cded.id,
        user_id: cded.user_id,
      }
    end
    Hmis::Hud::CustomDataElement.import!(cdes, validate: false)
  end

  def submission_class
    HmisExternalApis::ExternalForms::FormSubmission
  end

  def s3
    @s3 ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'hmis_external_form_submissions').first!.s3
  end

  # try not to make assumptions about str
  def parse_json(str)
    # some preflight sanity checks before we parse
    return nil unless str.present? && str[0] == '{' && str[-1] == '}' && str.size <= 100_000

    JSON.parse(str)
  rescue JSON::ParserError
    nil
  end
end
