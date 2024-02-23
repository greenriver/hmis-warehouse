# retrieve and process uploaded form submissions
class HmisExternalApis::TcHmis::ConsumeStaticFormsJob
  def perform
    download_from_s3.each do |data, metadata|
      HmisExternalApis::TcHmis::StaticPages::FormSubmission.create!(
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
