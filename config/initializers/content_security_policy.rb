# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  public_s3_url = ENV['S3_PUBLIC_URL'].present? ? "https://#{ENV['S3_PUBLIC_URL']}.s3.amazonaws.com/" : nil

  # Get Superset base URL for CSP if available
  superset_base_url = begin
    Superset.superset_base_url if defined?(Superset)
  rescue StandardError
    nil
  end

  policy.default_src(:self)
  policy.object_src(:none) # Prevents potentially dangerous browser plugins
  policy.base_uri(:self) # Only allows base URLs from your own domain, prevents cross-origin base URL injection
  policy.form_action( # Protects against form-action hijacking
    *[
      :self,
      ("https://#{ENV['FQDN']}" if ENV['FQDN'].present?), # explicit app domain for Okta auth
      ("https://#{ENV['OKTA_DOMAIN']}" if ENV['OKTA_DOMAIN'].present?), # okta auth form redirect location
      superset_base_url, # Superset dashboard integration
    ].compact_blank,
  )
  policy.frame_ancestors(
    *[
      :self, # Self-embedding for public reports
      superset_base_url, # Allow Superset to embed warehouse content
    ].compact_blank,
  ) # Prevents external clickjacking while allowing legitimate embedding

  policy.font_src(
    :self,
    :data,
    'https://fonts.gstatic.com', # Google font files
    'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.6.1/font/fonts/bootstrap-icons.woff',
  )
  policy.img_src(
    *[
      :self,
      :data,
      'https://*.openstreetmap.org',
      'https://fonts.gstatic.com', # Google font images/icons
      public_s3_url,
    ].compact_blank,
  )
  policy.script_src(
    :self,
    'https://browser.sentry-cdn.com',
    'https://cdnjs.cloudflare.com/ajax/libs/chance/1.0.4/chance.min.js',
    'https://unpkg.com/ag-grid-community@27.3.0/dist/ag-grid-community.min.noStyle.js',
    'https://unpkg.com/leaflet@1.7.1/dist/leaflet.js'
    'https://kit.fontawesome.com', # fonts in public reports
    'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.min.js', # Bootstrap and other libraries for public reports
    'https://d3js.org', # D3.js for data visualization in public reports
    :unsafe_inline,
    :unsafe_eval,
  )
  policy.style_src(
    *[
      :self,
      'https://fonts.googleapis.com',
      'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-grid.css',
      'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-theme-balham.css',
      'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/css/bootstrap.min.css',
      :unsafe_inline,
      public_s3_url,
    ].compact_blank
  )

  policy.connect_src(
    *[
      :self,
      :data, # allows fetch() from data uris, probably for d3
      ("wss://#{ENV['FQDN']}" if ENV['FQDN']),
      'https://sentry.io/',
      'https://*.ingest.sentry.io/',
      'https://*.ingest.us.sentry.io',
    ].compact_blank
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

    policy.report_uri("https://#{host}/api/#{project_id}/security/?sentry_key=#{public_key}")
  end
end

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

if Rails.env.production? || Rails.env.staging?
  Rails.application.config.content_security_policy_report_only = true
else
  Rails.application.config.content_security_policy_report_only = false
end
