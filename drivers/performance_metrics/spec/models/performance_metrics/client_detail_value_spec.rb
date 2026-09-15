###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMetrics::Client, type: :model do
  let(:user) { create(:user) }
  let(:destination_client) { create(:grda_warehouse_hud_client) }
  let(:client_row) do
    described_class.create!(
      client_id: destination_client.id,
      first_name: 'Jamie',
      last_name: 'Rivera',
      current_period_age: 34,
    )
  end

  describe '#detail_value' do
    context 'when the client is restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(true) }

      it 'redacts first_name and last_name' do
        expect(client_row.detail_value('first_name', user: user)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(client_row.detail_value('last_name', user: user)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      end
    end

    context 'when the client is not restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(false) }

      it 'returns the underlying pii values' do
        expect(client_row.detail_value('first_name', user: user)).to eq('Jamie')
        expect(client_row.detail_value('last_name', user: user)).to eq('Rivera')
      end
    end

    it 'passes non-pii columns through without resolving a pii policy' do
      expect(user).not_to receive(:reporting_policy_for_project)

      expect(client_row.detail_value('current_period_age', user: user)).to eq(34)
    end
  end
end
