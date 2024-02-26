###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# retrieve and process uploaded form submissions
class HmisExternalApis::ConsumeStaticFormsJob
  def perform
    download_from_s3.each do |data, metadata|
      HmisExternalApis::StaticPages::FormSubmission.create!(
        form_content_version: data.dig('submission', 'form_version'),
        submitted_at: data['submitted_at'],
        data: data['data'],
        spam_score: data['spam_score'],
        object_key: metadata['object_key'],
      )
      delete_from_s3(metadata['object_key'])
    end
  end

  def download_from_s3
    # TBD
  end
end
