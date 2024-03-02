###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# retrieve and process external form submissions
class HmisExternalApis::ConsumeExternalFormSubmissionsJob
  def perform
    download_from_s3.each do |data, metadata|
      submission = submission_class.transaction do
        process_submission(data, metadata)
      end
      # if we successfully processed the submission, delete it
      delete_from_s3(metadata['object_key']) if submission
    end
  end

  protected

  def process_submission(raw_data, metadata)
    object_key = metadata['object_key']
    submitted_at = DateTime.parse(metadata['submitted_at'])

    definition_id = raw_data['form_definition_id'].
      presence&.then { |value| ProtectedId::Encoder.decode(value) }
    if definition_id.nil?
      Rails.logger.error("external form submission #{object_key}: missing definition_id")
      return nil
    end

    spam_score = raw_data['spam_score'].presence&.to_i

    submission = submission_class.create!(
      submitted_at: submitted_at
      spam_score: spam_score,
      status: 'new',
      form_definition_id: definition_id,
      object_key: object_key,
      raw_data: raw_data
    )

    # TBD setup CDEs

    submission
  end

  def submission_class
    HmisExternalApis::ExternalForms::FormSubmission
  end

  def s3
    @s3 ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: 'hmis_external_form_submissions').first!.s3
  end

  def download_from_s3

    # TBD
  end

  def delete_from_s3(_object_key)
    # TBD
  end
end
