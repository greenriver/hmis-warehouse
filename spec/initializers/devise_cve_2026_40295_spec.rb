###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for CVE-2026-40295 (GHSA-jp94-3292-c3xv):
# Open redirect via unvalidated `request.referrer` in Timeoutable session timeout handler.
# Devise 5.0.4 fixes this natively (see Devise::Controllers::StoreLocation#extract_path_from_location);
# the app previously carried a monkey patch backporting this fix, which was removed once the gem upgrade
# landed. These specs confirm the native behavior still holds.
RSpec.describe 'CVE-2026-40295 - open redirect via Referer on timeout' do
  let(:store_location_host) { Class.new { include Devise::Controllers::StoreLocation }.new }

  describe 'extract_path_from_location' do
    def extract(location)
      store_location_host.send(:extract_path_from_location, location)
    end

    it 'strips scheme and host from an external URL, keeping only the path' do
      expect(extract('http://evil.example/phishing')).to eq('/phishing')
    end

    it 'preserves query string and fragment after stripping host' do
      expect(extract('http://evil.example/path?foo=bar#section')).to eq('/path?foo=bar#section')
    end

    it 'returns nil for a javascript: URI' do
      expect(extract('javascript:alert(1)')).to be_nil
    end

    it 'returns nil for a mailto: URI' do
      expect(extract('mailto:foo@example.com')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(extract(nil)).to be_nil
    end

    it 'returns nil for an unparseable URI' do
      expect(extract('/foo.bar">Carry')).to be_nil
    end

    it 'passes through a plain path unchanged' do
      expect(extract('/dashboard')).to eq('/dashboard')
    end
  end
end
