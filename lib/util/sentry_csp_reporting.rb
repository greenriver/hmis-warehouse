###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Builds the CSP violation-reporting values for a Sentry DSN, covering both the
# deprecated `report-uri` directive and its Reporting API replacement (`report-to`
# plus the `Reporting-Endpoints`/`Report-To` headers), since browsers that support
# `report-to` ignore `report-uri` outright rather than falling back to it.
# See https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/report-to
class SentryCspReporting
  class InvalidDsnError < StandardError
  end

  REPORT_GROUP = 'csp-endpoint'

  attr_reader :report_uri

  def initialize(sentry_dsn)
    # SENTRY_DSN=https://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@o256059.ingest.sentry.io/1111111111111111
    # report_uri=https://o256059.ingest.sentry.io/api/1111111111111111/security/?sentry_key=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    # see https://docs.sentry.io/platforms/ruby/guides/rails/security-policy-reporting/
    uri = URI.parse(sentry_dsn)
    public_key = uri.user.presence
    host = uri.host.presence
    project_id = uri.path&.split('/')&.last.presence
    raise InvalidDsnError, 'Invalid sentry dsn' unless uri.scheme == 'https' && public_key && host && project_id && project_id =~ /\A\d+\z/

    @report_uri = "https://#{host}/api/#{project_id}/security/?sentry_key=#{public_key}"
  end

  def report_to_directive_value
    REPORT_GROUP
  end

  def reporting_endpoints_header
    %(#{REPORT_GROUP}="#{report_uri}")
  end

  # Older Reporting API v0 shape, kept for browsers that never picked up the
  # newer `Reporting-Endpoints` header.
  def report_to_header
    {
      group: REPORT_GROUP,
      max_age: 10_886_400,
      endpoints: [{ url: report_uri }],
      include_subdomains: true,
    }.to_json
  end
end
