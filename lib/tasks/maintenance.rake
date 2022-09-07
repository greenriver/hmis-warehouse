namespace :maintenance do
  desc 'Create maintenance page'
  task create: [:environment] do
    require 'aws-sdk-s3'
    include Rails.application.routes.url_helpers
    destination = 'public/maintenance.html'

    # This will only run if the web server is accessible
    source = if Rails.env.development?
      'https://qa-warehouse.openpath.host/maintenance_saver'
    else
      maintenance_saver_index_url(host: ENV['FQDN'], protocol: 'https')
    end

    # catch first deployments, we'll build on subsequent calls
    uri = URI(source)
    res = Net::HTTP.get_response(uri)
    exit unless res.code.to_s == '200'

    premailer = Premailer.new(source)

    client = Aws::S3::Client.new
    bucket = ENV.fetch('ASSETS_BUCKET_NAME')
    prefix = ENV.fetch('ASSETS_PREFIX')

    if bucket.blank? || prefix.blank?
      puts 'ENV[ASSETS_BUCKET_NAME] and ENV[ASSETS_PREFIX] must be specified'
      next
    end

    key = File.join(prefix, destination)
    puts "Uploading #{key} to #{bucket}"
    resp = client.put_object(
      bucket: bucket,
      key: key,
      body: premailer.to_inline_css,
      content_disposition: 'inline',
      content_type: 'text/html',
    )
    if resp.etag
      puts 'Successfully uploaded maintenance file to s3'
    else
      puts 'Unable to upload maintenance file'
    end
  end
end
