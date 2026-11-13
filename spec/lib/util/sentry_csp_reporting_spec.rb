###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SentryCspReporting do
  let(:dsn) { 'https://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@o256059.ingest.sentry.io/1111111111111111' }
  let(:security_endpoint) { 'https://o256059.ingest.sentry.io/api/1111111111111111/security/?sentry_key=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }

  subject(:reporting) { described_class.new(dsn) }

  describe '#report_uri' do
    it 'builds the sentry security endpoint from the dsn' do
      expect(reporting.report_uri).to eq(security_endpoint)
    end
  end

  describe '#reporting_endpoints_header' do
    it 'maps the report group name to the security endpoint' do
      expect(reporting.reporting_endpoints_header).to eq(%(csp-endpoint="#{security_endpoint}"))
    end
  end

  describe '#report_to_header' do
    it 'builds the Reporting API v0 payload for the report group' do
      expect(JSON.parse(reporting.report_to_header)).to eq(
        'group' => 'csp-endpoint',
        'max_age' => 10_886_400,
        'endpoints' => [{ 'url' => security_endpoint }],
        'include_subdomains' => true,
      )
    end
  end

  describe '#report_to_directive_value' do
    it 'is the report group name referenced by the report-to CSP directive' do
      expect(reporting.report_to_directive_value).to eq('csp-endpoint')
    end
  end

  context 'with an invalid dsn' do
    it 'raises when the scheme is not https' do
      expect { described_class.new('http://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@o256059.ingest.sentry.io/1111111111111111') }.
        to raise_error(SentryCspReporting::InvalidDsnError)
    end

    it 'raises when the public key is missing' do
      expect { described_class.new('https://o256059.ingest.sentry.io/1111111111111111') }.
        to raise_error(SentryCspReporting::InvalidDsnError)
    end

    it 'raises when the project id is not numeric' do
      expect { described_class.new('https://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@o256059.ingest.sentry.io/not-a-project-id') }.
        to raise_error(SentryCspReporting::InvalidDsnError)
    end
  end
end
