###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisDataQualityTool::Client, type: :model do
  describe '#ssn_issue_reason' do
    it 'names why a "Full SSN reported" SSN fails the SSN check' do
      aggregate_failures do
        expect(described_class.new(ssn: nil, ssn_data_quality: 1).ssn_issue_reason).to eq('SSN is blank.')
        expect(described_class.new(ssn: '912345678', ssn_data_quality: 1).ssn_issue_reason).to eq('First three digits cannot be "000," "666," or in the 900 series.')
        expect(described_class.new(ssn: '123456780', ssn_data_quality: 1).ssn_issue_reason).to eq('')
      end
    end

    it 'is blank for other SSN Data Quality responses, which explain themselves' do
      aggregate_failures do
        [2, 8, 9, 99, nil].each do |dq|
          expect(described_class.new(ssn: '912345678', ssn_data_quality: dq).ssn_issue_reason).to be_nil, "for #{dq.inspect}"
          expect(described_class.new(ssn: nil, ssn_data_quality: dq).ssn_issue_reason).to be_nil, "for #{dq.inspect}"
        end
      end
    end
  end

  describe 'Invalid SSN Reason column' do
    let(:client) { described_class.new(ssn: '912345678', ssn_data_quality: 1) }

    it 'is redacted for viewers who cannot see the full SSN' do
      aggregate_failures do
        allowed = GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance
        denied = GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
        expect(client.download_value(:ssn_issue_reason, pii_policy: allowed)).to include('900 series')
        expect(client.download_value(:ssn_issue_reason, pii_policy: denied)).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      end
    end

    it 'is in exports only when the SSN is' do
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original

      aggregate_failures do
        [true, false].each do |include_pii|
          allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(include_pii)
          keys = described_class.detail_headers_for(:ssn_issues, nil, export: true).keys
          expect(keys.include?(:ssn_issue_reason)).to eq(include_pii)
          expect(keys.include?(:ssn)).to eq(include_pii)
        end
      end
    end
  end
end
