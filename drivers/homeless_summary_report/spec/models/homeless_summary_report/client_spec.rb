###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomelessSummaryReport::Client, type: :model do
  let(:user) { create(:user) }

  describe '#display_value' do
    describe 'HMIS client restriction' do
      let!(:hmis_ds) { create(:hmis_primary_data_source) }
      let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
      let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
      let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

      before do
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        allow(user).to receive(:policy_for).and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
      end

      it 'redacts the restricted client and leaves the unrestricted client intact' do
        restricted_report_client = described_class.new(client_id: restricted_destination_client.id, first_name: 'Restricted', last_name: 'Client')
        open_report_client = described_class.new(client_id: open_destination_client.id, first_name: 'Open', last_name: 'Doe')

        restricted_policy = user.reporting_policy_for_client(client: restricted_destination_client, mode: :browse)
        open_policy = user.reporting_policy_for_client(client: open_destination_client, mode: :browse)

        expect(restricted_report_client.display_value(:first_name, pii_policy: restricted_policy)).to eq('Redacted')
        expect(restricted_report_client.display_value(:last_name, pii_policy: restricted_policy)).to eq('Redacted')
        expect(open_report_client.display_value(:first_name, pii_policy: open_policy)).to eq('Open')
        expect(open_report_client.display_value(:last_name, pii_policy: open_policy)).to eq('Doe')
      end
    end
  end
end
