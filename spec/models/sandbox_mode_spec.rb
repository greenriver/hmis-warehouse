###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SandboxMode do
  around do |example|
    keys = ['SANDBOX_MODE', 'SANDBOX_EMAIL_ALLOWED_DOMAINS']
    originals = keys.index_with { |k| ENV.fetch(k, nil) }
    example.run
  ensure
    originals.each { |k, v| ENV[k] = v }
  end

  describe '.enabled?' do
    it 'is true for "true"' do
      ENV['SANDBOX_MODE'] = 'true'
      expect(described_class.enabled?).to eq(true)
    end

    [nil, 'false', 'TRUE', '1'].each do |value|
      it "is false when SANDBOX_MODE is #{value.inspect}" do
        ENV['SANDBOX_MODE'] = value
        expect(described_class.enabled?).to eq(false)
      end
    end
  end

  describe '.filter' do
    let!(:credential) { create(:grda_remote_s3) }

    it 'returns the relation unchanged when disabled' do
      expect(described_class.filter(GrdaWarehouse::RemoteCredential.all)).to contain_exactly(credential)
    end

    it 'returns an empty relation when enabled' do
      with_sandbox_mode do
        expect(described_class.filter(GrdaWarehouse::RemoteCredential.all).null_relation?).to eq(true)
      end
    end
  end

  describe '.guard!' do
    it 'raises IntegrationDisabled naming the integration when enabled' do
      with_sandbox_mode do
        expect { described_class.guard!('CSG Engage') }.
          to raise_error(SandboxMode::IntegrationDisabled, 'CSG Engage is disabled in sandbox mode')
      end
    end

    it 'returns nil when disabled' do
      ENV['SANDBOX_MODE'] = nil
      expect(described_class.guard!('CSG Engage')).to be_nil
    end
  end

  describe '.config_warnings' do
    it 'is empty when neither variable is set' do
      ENV['SANDBOX_MODE'] = nil
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = nil
      expect(described_class.config_warnings).to eq([])
    end

    it 'reports sandbox mode on' do
      ENV['SANDBOX_MODE'] = 'true'
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = nil
      expect(described_class.config_warnings).to eq(['SANDBOX_MODE is on: external integrations are disabled and required training is skipped'])
    end

    ['1', 'TRUE', 'yes'].each do |value|
      it "reports SANDBOX_MODE=#{value} as ignored" do
        ENV['SANDBOX_MODE'] = value
        ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = nil
        expect(described_class.config_warnings).
          to eq(["SANDBOX_MODE is set to #{value.inspect} and is ignored; only \"true\" enables sandbox mode"])
      end
    end

    it 'does not report an empty SANDBOX_MODE' do
      ENV['SANDBOX_MODE'] = ''
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = nil
      expect(described_class.config_warnings).to eq([])
    end

    it 'reports the allowed-domain count without the domains' do
      ENV['SANDBOX_MODE'] = nil
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = 'example.org, Partner.gov,'
      expect(described_class.config_warnings).
        to eq(['SANDBOX_EMAIL_ALLOWED_DOMAINS is set: outgoing email is limited to 2 allowed domain(s)'])
    end

    it 'reports an empty allow-list as dropping all email' do
      ENV['SANDBOX_MODE'] = nil
      ENV['SANDBOX_EMAIL_ALLOWED_DOMAINS'] = ''
      expect(described_class.config_warnings).
        to eq(['SANDBOX_EMAIL_ALLOWED_DOMAINS is set: outgoing email is limited to 0 allowed domain(s)'])
    end
  end
end
