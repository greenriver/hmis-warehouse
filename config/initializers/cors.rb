# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend HMIS app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    cors_hosts = ENV['CORS_HOSTS']
    return unless cors_hosts.present?

    origins [cors_hosts]

    resource '/api/*', headers: :any, methods: [:get, :post, :delete, :options]
  end
end
