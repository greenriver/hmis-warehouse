###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaReports::MonthlyPerformance::Enrollment, type: :model do
  let(:user) { create(:user) }
  let(:destination_client) { create(:grda_warehouse_hud_client) }
  let(:enrollment) do
    described_class.create!(
      client_id: destination_client.id,
      entry_date: Date.current,
      first_name: 'Jamie',
      last_name: 'Rivera',
      stay_length_in_days: 10,
    )
  end

  describe '#detail_value' do
    context 'when the client is restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(true) }

      it 'redacts first_name and last_name' do
        expect(enrollment.detail_value(:first_name, user: user)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(enrollment.detail_value(:last_name, user: user)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      end
    end

    context 'when the client is not restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(false) }

      it 'returns the underlying pii values' do
        expect(enrollment.detail_value(:first_name, user: user)).to eq('Jamie')
        expect(enrollment.detail_value(:last_name, user: user)).to eq('Rivera')
      end
    end

    it 'passes non-pii columns through without resolving a pii policy' do
      expect(user).not_to receive(:reporting_policy_for_project)

      expect(enrollment.detail_value(:stay_length_in_days, user: user)).to eq(10)
    end
  end
end
