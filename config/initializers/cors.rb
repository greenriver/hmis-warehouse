# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

hmis_hostname = ENV['HMIS_HOSTNAME']
if ENV['ENABLE_HMIS_API'] == 'true' && hmis_hostname.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins hmis_hostname

      # Allow requests to /hmis from the HMIS frontend host for the API
      resource '/hmis/*',
        headers: :any,
        methods: [:get, :post, :delete, :put, :patch, :options, :head],
        credentials: true

      if ENV['OKTA_DOMAIN'].present?
        # Allow requests to the SSO okta endpoints for authentication
        resource '/users/auth/okta',
          headers: :any,
          methods: [:get, :post, :delete, :put, :patch, :options, :head],
          credentials: true
      end
    end
  end
end
