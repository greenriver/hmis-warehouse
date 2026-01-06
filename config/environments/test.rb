# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # enable reloading if we're using spring. Note
  if ENV['DISABLE_SPRING'].present?
    config.enable_reloading = false
  else
    # spring enabled
    config.enable_reloading = true
  end

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  # config.eager_load = ENV['CI'].present?
  # disabling this in an attempt to reduce memory usage in CI
  config.eager_load = false

  config.action_view.cache_template_loading = true

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}",
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  # Use Redis cache store for system tests (needed for impersonation state)
  # Regular tests use null_store for speed
  if ENV['RUN_SYSTEM_TESTS']
    config.cache_store = :redis_cache_store, { url: "redis://#{ENV.fetch('CACHE_HOST', 'redis')}:#{ENV.fetch('CACHE_PORT', 6379)}/#{ENV.fetch('CACHE_DB', 1)}" }
  else
    config.cache_store = :null_store
  end

  # time zone - use UTC for tests to match database and container timezone and HMIS front-end JS
  # Production/staging use TIMEZONE environment variable (defaults to America/New_York)
  config.time_zone = 'UTC'

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test
  # Re-enable ActiveStorage routes in test so Disk service URL helpers exist
  config.active_storage.draw_routes = true

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.active_job.queue_adapter = :test

  # Unlike controllers, the mailer instance doesn't have any context about the
  # incoming request so you'll need to provide the :host parameter yourself.
  # config.action_mailer.default_url_options = { host: "www.example.com" }
  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  config.active_support.deprecation = :raise

  # Raise exceptions for disallowed deprecations.
  # config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  # config.active_support.disallowed_deprecation_warnings = []

  # don't need email sandbox with letter opener
  config.sandbox_email_mode = false

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  # FIXME: would be nice to enable this but we'd need to fix global before_actions in ApplicationController
  # config.action_controller.raise_on_missing_callback_actions = true
  config.action_controller.raise_on_missing_callback_actions = false

  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  routes.default_url_options = { host: ENV['FQDN'] }

  config.force_ssl = false

  # Enable asset compilation for system tests
  if ENV['RUN_RAILS_SYSTEM_TESTS'] == 'true' || ENV['RUN_SYSTEM_TESTS'] == 'true'
    config.assets.compile = true
    config.assets.check_precompiled_asset = false
    config.assets.digest = false
  end
end
