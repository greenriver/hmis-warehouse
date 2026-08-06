###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

require_relative '../../lib/util/sentry_csp_reporting'

sentry_dsn = ENV['WAREHOUSE_SENTRY_DSN'].presence
sentry_csp_reporting = SentryCspReporting.new(sentry_dsn) if sentry_dsn

# allow whitespace to make the configuration easier to read
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

      # Development
      ('https://cdnjs.cloudflare.com/ajax/libs/chance/' if Rails.env.development?), # DevTools fetches chance.min.js.map under connect-src, not script-src
    ].compact_blank,
  )

  # Report CSP violations to Sentry. `report-uri` is deprecated in favor of `report-to`,
  # but browsers that don't yet support `report-to` ignore it, so both are sent -- see
  # SentryCspReporting for the header values this depends on.
  if sentry_csp_reporting
    policy.report_uri(sentry_csp_reporting.report_uri)
    policy.directives['report-to'] = [sentry_csp_reporting.report_to_directive_value]
  end
end

if sentry_csp_reporting
  Rails.application.config.action_dispatch.default_headers['Reporting-Endpoints'] = sentry_csp_reporting.reporting_endpoints_header
  Rails.application.config.action_dispatch.default_headers['Report-To'] = sentry_csp_reporting.report_to_header
end

# A fresh random nonce per request (not session-based, which would be reused
# across requests and weaken the anti-replay property nonces are meant to provide)
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = ['script-src']

if ENV['CSP_REPORT_ONLY'] == '1'
  Rails.application.config.content_security_policy_report_only = true
else
  # the default is to enforce the CSP
  Rails.application.config.content_security_policy_report_only = false
end
