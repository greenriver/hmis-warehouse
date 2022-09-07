namespace :maintenance do
  desc 'Create maintenance page'
  task create: [:environment] do
    require 'aws-sdk-s3'
    include Rails.application.routes.url_helpers
    destination = 'public/maintenance.html'

    warden_proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
      i.set_user(nil, scope: :user, store: false, run_callbacks: false)
    end
    renderer = MaintenanceController.renderer.new(
      'warden' => warden_proxy,
    )
    source = renderer.render(
      template: 'maintenance/index',
      layout: 'maintenance',
      assigns: { maintenance: true },
    )
    premailer = Premailer.new(source, with_html_string: true)

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
