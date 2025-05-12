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
  config.cache_store = :null_store

  # time zone
  config.time_zone = 'America/New_York'

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

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

  # Devise requires a default URL
  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  routes.default_url_options = { host: ENV['FQDN'] }

  config.force_ssl = false
end
