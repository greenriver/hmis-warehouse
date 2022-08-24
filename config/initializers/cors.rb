# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

hmis_hostname = ENV['HMIS_HOSTNAME']
if ENV['ENABLE_HMIS_API'] == 'true' && hmis_hostname.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    # Allow requests to /hmis from the HMIS frontend host
    allow do
      origins hmis_hostname

      resource '/hmis/*',
        headers: :any,
        methods: [:get, :post, :delete, :put, :patch, :options, :head],
        credentials: true
    end
  end
end
