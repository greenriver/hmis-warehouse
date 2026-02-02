# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# CSP DOCUMENTATION STANDARDS:
# =================================
# Every CSP rule MUST include an inline comment explaining its purpose and rationale.
# Comments should be specific enough to understand why the rule exists and what functionality it enables.
#
# EXTERNAL ASSET CATEGORIES:
# - Core Application: Assets required for basic app functionality
# - Data Visualization & Analytics: Assets for charts, maps, and data analysis features
# - Authentication: Assets required for auth flows (Okta, reCAPTCHA, etc.)
# - Monitoring: Assets for error tracking and monitoring (Sentry)
# - Public Reports: External CDN assets specifically for public-facing reports and dashboards
#
# Most external asset rules support core application functionality including internal operations,
# administrative reporting, data visualization, and public-facing dashboards.

# allow whitespace to make the configuration easier to read
# rubocop:disable Layout/EmptyLinesAroundArguments
Rails.application.config.content_security_policy do |policy|
  public_s3_url = ENV['S3_PUBLIC_URL'].present? ? "https://#{ENV['S3_PUBLIC_URL']}.s3.amazonaws.com/" : nil

  policy.default_src(:self)
  policy.object_src(:none) # Prevents potentially dangerous browser plugins
  policy.base_uri(:self) # Only allows base URLs from your own domain, prevents cross-origin base URL injection

  policy.frame_ancestors(
    *[
      :self, # Self-embedding for public reports
      # superset_base_url, # In the future, we plan to allow warehouse to embed Superset content
    ].compact_blank,
  ) # Prevents external clickjacking while allowing legitimate embedding

  policy.frame_src(
    :self,

    # Authentication
    'https://www.google.com/recaptcha/', # Google reCAPTCHA iframe for form protection
    'https://recaptcha.google.com/recaptcha/', # Google reCAPTCHA fallback iframe
  )
  policy.font_src(
    :self,
    :data, # Data URIs for inline fonts (base64 encoded)

    # Core Application
    'https://fonts.gstatic.com', # Google Fonts font files

    # Public Reports - UI Components
    'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/', # Bootstrap Icons font files
    'https://ka-f.fontawesome.com/releases/v5.15.4/webfonts/', # FontAwesome webfonts
  )
  policy.img_src(
    *[
      :self,
      :data, # Data URIs for inline images (base64 encoded)

      # Core Application
      'https://fonts.gstatic.com', # Google Fonts icons and font images
      public_s3_url, # S3 bucket for uploaded images and assets (if configured)

      # Data Visualization & Analytics
      'https://*.openstreetmap.org', # OpenStreetMap tile images for location visualizations
    ].compact_blank,
  )

  policy.script_src(
    :self,
    # Monitoring
    'https://browser.sentry-cdn.com', # Sentry error tracking and monitoring

    # Authentication
    'https://www.google.com/recaptcha/', # Google reCAPTCHA form protection
    'https://www.gstatic.com/recaptcha/', # Google reCAPTCHA static assets

    # Core Application
    'https://unpkg.com/ag-grid-community@27.3.0/', # Data grid component for large datasets
    'https://cdnjs.cloudflare.com/ajax/libs/chance/', # Random data generation for development

    # Data Visualization & Analytics
    'https://d3js.org', # D3.js library for health outcomes visualization, client timeline charts, geographic service area maps, initiative reporting dashboards, and interactive data analytics
    'https://cdn.jsdelivr.net/npm/billboard.js@3.18.0/dist/billboard.min.js', # Billboard.js library (patched version)
    'https://cdnjs.cloudflare.com/ajax/libs/billboard.js/', # deprecated
    'https://unpkg.com/leaflet@1.7.1/dist/', # Leaflet mapping library for client location tracking, service area visualization, geolocation capture, and geographic reporting
    'https://unpkg.com/leaflet@1.9.4/dist/', # Leaflet mapping library - newer version used in external forms

    # Public Reports - UI Components
    'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/', # Bootstrap framework for responsive UI
    'https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/', # Bootstrap framework - version used in external forms
    'https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/', # Bootstrap framework - version used in performance measurement
    'https://cdn.jsdelivr.net/npm/bootstrap-datepicker@1.9.0/dist/js/', # Date picker component
    'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.9.0/js/', # Date picker component (cdnjs)
    'https://code.jquery.com', # jQuery for DOM manipulation and event handling
    'https://kit.fontawesome.com/b8b025dd15.js', # FontAwesome icons for public reports

    :unsafe_inline, # Required for inline scripts in HAML templates
    :unsafe_eval, # Required for some JavaScript libraries that use eval()
  )

  policy.style_src(
    *[
      :self,

      # Core Application
      'https://fonts.googleapis.com', # Google Fonts for typography
      'https://unpkg.com/ag-grid-community@27.3.0/styles/', # AG Grid component styles
      :unsafe_inline, # Required for inline styles in HAML templates
      public_s3_url, # S3 bucket for uploaded assets (if configured)

      # Data Visualization & Analytics
      'https://cdn.jsdelivr.net/npm/billboard.js@3.18.0/dist/billboard.min.css', # Billboard.js chart styling
      'https://cdnjs.cloudflare.com/ajax/libs/billboard.js/', # deprecated
      'https://unpkg.com/leaflet@1.7.1/dist/', # Leaflet mapping library styles
      'https://unpkg.com/leaflet@1.9.4/dist/', # Leaflet mapping library styles - newer version

      # Public Reports - UI Components
      'https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/', # Bootstrap framework styles
      'https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/', # Bootstrap framework styles - version used in external forms
      'https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/', # Bootstrap framework styles - version used in performance measurement
      'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/', # Bootstrap icon font
      'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/', # Bootstrap date picker
    ].compact_blank,
  )

  policy.connect_src(
    *[
      :self,
      :data, # Data URIs for fetch() requests
      ("wss://#{ENV['FQDN']}" if ENV['FQDN']), # WebSocket connections for real-time features

      # Monitoring
      'https://sentry.io/', # Sentry error reporting
      'https://*.ingest.sentry.io/', # Sentry data ingestion endpoints
      'https://*.ingest.us.sentry.io', # Sentry US region ingestion endpoints

      # Public Reports - UI Components
      'https://ka-f.fontawesome.com/releases/', # FontAwesome asset loading and updates
    ].compact_blank,
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

if ENV['CSP_REPORT_ONLY'] == '1'
  Rails.application.config.content_security_policy_report_only = true
else
  # the default is to enforce the CSP
  Rails.application.config.content_security_policy_report_only = false
end
# rubocop:enable Layout/EmptyLinesAroundArguments
