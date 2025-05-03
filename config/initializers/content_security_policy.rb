# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src(:self)
  policy.object_src(:none) # Prevents potentially dangerous browser plugins
  policy.base_uri(:self) # Only allows base URLs from your own domain, prevents cross-origin base URL injection
  policy.form_action(:self) # Protects against form-action hijacking
  policy.frame_ancestors(:none) # Prevents clickjacking attacks (UI redressing attacks)

  policy.font_src(
    :self,
    :data,
    'https://fonts.gstatic.com', # Google font files
  )
  policy.img_src(
    :self,
    :data,
    'https://tile.openstreetmap.org',
  )
  policy.script_src(
    :self,
    'https://browser.sentry-cdn.com',
    'https://cdnjs.cloudflare.com/ajax/libs/chance/1.0.4/chance.min.js',
    'https://unpkg.com/ag-grid-community@27.3.0/dist/ag-grid-community.min.noStyle.js',
    :unsafe_inline,
    :unsafe_eval,
  )
  policy.style_src(
    :self,
    'https://fonts.googleapis.com',
    'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-grid.css',
    'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-theme-balham.css',
    :unsafe_inline,
  )
  policy.connect_src(
    :self,
    'https://sentry.io/',
    'https://*.ingest.sentry.io/',
  )

  # Report CSP violations to a specified URI
  sentry_dsn = ENV['WAREHOUSE_SENTRY_DSN'].presence
  if sentry_dsn
    # transform the DSN into the sentry reporting uri
    # SENTRY_DSN=https://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@o256059.ingest.sentry.io/1111111111111111
    # report_uri=https://o256059.ingest.sentry.io/api/1111111111111111/security/?sentry_key=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    # see https://docs.sentry.io/platforms/javascript/guides/express/security-policy-reporting/

    uri = URI.parse(sentry_dsn)
    public_key = uri.user.presence
    host = uri.host.presence
    project_id = uri.path&.split('/')&.last.presence
    raise 'Invalid sentry dsn' unless uri.scheme == 'https' && public_key && host && project_id && project_id =~ /\A\d+\z/

    policy.report_uri = "https://#{host}/api/#{project_id}/security/?sentry_key=#{public_key}"
  end
end

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

if Rails.env.production? || Rails.env.staging?
  Rails.application.config.content_security_policy_report_only = true
else
  Rails.application.config.content_security_policy_report_only = false
end
