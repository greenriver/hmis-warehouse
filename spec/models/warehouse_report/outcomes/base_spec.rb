###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReport::Outcomes::Base::Support, type: :model do
  let(:user) { create(:user) }
  let(:support) { described_class.new(clients: [], rows: [], headers: ['first_name']) }

  describe '#display_value' do
    it 'does not raise when neither project_id nor client_id is present' do
      expect do
        support.display_value(header: 'first_name', value: 'Jamie', project_id: nil, client_id: nil, user: user)
      end.not_to raise_error
    end

    it 'does not redact the value under the fallback policy' do
      result = support.display_value(header: 'first_name', value: 'Jamie', project_id: nil, client_id: nil, user: user)
      expect(result).to eq('Jamie')
    end

    context 'HMIS client restriction' do
      let!(:hmis_ds) { create(:hmis_primary_data_source) }
      let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
      let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
      let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }
      let(:support) { described_class.new(clients: [], rows: [[restricted_destination_client.id], [open_destination_client.id]], headers: ['first_name']) }

      before do
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        allow(user).to receive(:policy_for).with(anything, policy_class: GrdaWarehouse::AuthPolicies::DestinationClientPolicy).and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
      end

      it 'redacts the restricted client and leaves the unrestricted client intact' do
        restricted_result = support.display_value(header: 'first_name', value: 'Restricted', project_id: nil, client_id: restricted_destination_client.id, user: user)
        open_result = support.display_value(header: 'first_name', value: 'Open', project_id: nil, client_id: open_destination_client.id, user: user)

        expect(restricted_result).to eq('Redacted')
        expect(open_result).to eq('Open')
      end

      it 'looks up destination clients once for the row set rather than once per display_value call' do
        support.display_value(header: 'first_name', value: 'Restricted', project_id: nil, client_id: restricted_destination_client.id, user: user)

        expect(GrdaWarehouse::Hud::Client).not_to receive(:where)
        support.display_value(header: 'first_name', value: 'Open', project_id: nil, client_id: open_destination_client.id, user: user)
      end
    end
  end
end
