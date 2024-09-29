require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # enable reloading if we're using spring. Note
  # note, newer versions of rails replace config.cache_classes with enable_reloading
  if (ENV['DISABLE_SPRING'].presence || '0') != '0'
    # spring enabled
    config.cache_classes = false
  else
    config.cache_classes = true
  end

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  config.action_view.cache_template_loading = true
  config.cache_store = :null_store

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}",
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # time zone
  config.time_zone = 'America/New_York'

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.active_job.queue_adapter = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :raise

  # don't need email sandbox with letter opener
  config.sandbox_email_mode = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Devise requires a default URL
  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  routes.default_url_options = { host: ENV['FQDN'] }

  config.force_ssl = false
end
