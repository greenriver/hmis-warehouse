###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CePerformance::Report, type: :model do
  let(:report) { described_class.create!(user_id: User.system_user.id) }
  let(:destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Destination', LastName: 'Client') }
  let(:user) { create(:user) }
  let(:client_row) do
    CePerformance::Client.create!(
      report_id: report.id,
      destination_client_id: destination_client.id,
      period: 'reporting',
      household_size: 2,
      first_name: 'Jamie',
      last_name: 'Rivera',
      dob: Date.new(1990, 1, 1),
    )
  end

  describe '#client_value' do
    context 'when the client is restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(true) }

      it 'redacts first_name, last_name, and dob' do
        expect(report.client_value(client_row, 'first_name', user: user, mode: :browse)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(report.client_value(client_row, 'last_name', user: user, mode: :browse)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(report.client_value(client_row, 'dob', user: user, mode: :browse)).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      end
    end

    context 'when the client is not restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(false) }

      it 'returns the underlying pii values' do
        expect(report.client_value(client_row, 'first_name', user: user, mode: :browse)).to eq('Jamie')
        expect(report.client_value(client_row, 'last_name', user: user, mode: :browse)).to eq('Rivera')
        expect(report.client_value(client_row, 'dob', user: user, mode: :browse)).to eq(Date.new(1990, 1, 1))
      end
    end

    it 'passes non-pii columns through without resolving a pii policy' do
      expect(user).not_to receive(:reporting_policy_for_project)

      expect(report.client_value(client_row, 'household_size', user: user, mode: :browse)).to eq(2)
    end

    it 'resolves source_client-prefixed columns via the source client association' do
      expect(report.client_value(client_row, 'source_client.first_name', user: user, mode: :browse)).to eq('Destination')
    end
  end
end
