# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# Verifies the monkey patch for CVE-2026-40295 (GHSA-jp94-3292-c3xv):
# Open redirect via unvalidated `request.referrer` in Timeoutable session timeout handler.
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

  describe 'patches are applied to the active authentication chain' do
    it 'resolves FailureApp#redirect_url from the monkey patch, not the gem' do
      source_file, = Devise::FailureApp.instance_method(:redirect_url).source_location
      expect(source_file).to end_with('devise_cve_2026_40295.rb')
    end

    it 'resolves extract_path_from_location from the monkey patch, not the gem' do
      source_file, = Devise::Controllers::StoreLocation.instance_method(:extract_path_from_location).source_location
      expect(source_file).to end_with('devise_cve_2026_40295.rb')
    end

    it 'CustomAuthFailure inherits the patched redirect_url' do
      source_file, = CustomAuthFailure.instance_method(:redirect_url).source_location
      expect(source_file).to end_with('devise_cve_2026_40295.rb')
    end

    it 'Warden is configured to use CustomAuthFailure as the failure app' do
      failure_app = Devise.warden_config.failure_app
      expect(failure_app).to eq(CustomAuthFailure)
      expect(failure_app).to be < Devise::FailureApp
    end
  end
end
