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
        form_name: data.dig('submission', 'form_name'),
        form_version: data.dig('submission', 'version'),
        submitted_at: data['submitted_at'],
        data: data['data'],
        score: data['spam_score'],
        remote_location: metadata['key'],
      )
      delete_from_s3(metadata['key'])
    end
  end

  def download_from_s3
    # TBD
  end
end
