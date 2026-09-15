###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemPathways::Report, type: :model do
  let(:user) { create(:user) }
  let(:destination_client) { create(:grda_warehouse_hud_client) }
  let(:report) { described_class.create!(user_id: user.id) }
  let!(:client_row) do
    SystemPathways::Client.create!(
      report_id: report.id,
      client_id: destination_client.id,
      first_name: 'Jamie',
      last_name: 'Rivera',
    )
  end
  let(:enrollment) do
    SystemPathways::Enrollment.create!(
      report_id: report.id,
      client_id: destination_client.id,
      project_id: 1,
      enrollment_id: 1,
      project_type: 1,
    )
  end

  describe '#detail_headers' do
    context 'when the client is restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(true) }

      it 'redacts first_name and last_name' do
        headers = report.detail_headers(user: user)

        expect(headers['First Name'].call(enrollment)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(headers['Last Name'].call(enrollment)).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      end
    end

    context 'when the client is not restricted' do
      before { allow(user.policy_context).to receive(:client_restricted?).with(destination_client.id).and_return(false) }

      it 'returns the underlying pii values' do
        headers = report.detail_headers(user: user)

        expect(headers['First Name'].call(enrollment)).to eq('Jamie')
        expect(headers['Last Name'].call(enrollment)).to eq('Rivera')
      end
    end
  end
end
