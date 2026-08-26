###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ClientAccessControl::History pdf template redaction' do
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  it 'redacts the client name' do
    client_history = ClientHistory.new(client_id: restricted_destination_client.id, user_id: 0)
    html = PdfGenerator.html(
      controller: ClientAccessControl::HistoryController,
      template: 'client_access_control/history/pdf',
      layout: false,
      user: User.system_user,
      assigns: { client_history: client_history },
    )

    expect(html).not_to include('Restricted Client')
    expect(html).to include('Name Redacted')
  end
end
