namespace :maintenance do
  desc 'Create maintenance page'
  task create: [:environment] do
    # if Rails.env.development?
    #   puts 'This will only run if the web server is accessible'
    #   exit
    # end

    require 'aws-sdk-s3'
    include Rails.application.routes.url_helpers
    destination = 'public/m_503.html'
    source = maintenance_index_url(host: ENV['FQDN'], protocol: 'https')
    source = 'https://qa-warehouse.openpath.host/502'
    premailer = Premailer.new(source)

    File.open(destination, 'wb') do |file|
      file.puts(premailer.to_inline_css)
    end

    client = Aws::S3::Client.new
    bucket = ENV.fetch('ASSETS_BUCKET_NAME')
    prefix = ENV.fetch('ASSETS_PREFIX')

    if bucket.blank? || prefix.blank?
      puts 'ENV[ASSETS_BUCKET_NAME] and ENV[ASSETS_PREFIX] must be specified'
      exit
    end

    resp = client.list_objects(
      {
        bucket: bucket,
        prefix: prefix,
      }
    )
    keys = resp.to_h[:contents]&.map { |r| r[:key] }
    puts keys.inspect
  end
end
