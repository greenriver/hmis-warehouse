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

  def render_history_pdf(client_id:, user_id: 0)
    client_history = ClientHistory.new(client_id: client_id, user_id: user_id)
    PdfGenerator.html(
      controller: ClientAccessControl::HistoryController,
      template: 'client_access_control/history/pdf',
      layout: false,
      user: User.system_user,
      assigns: { client_history: client_history },
    )
  end

  it 'redacts the client name' do
    html = render_history_pdf(client_id: restricted_destination_client.id)

    expect(html).not_to include('Restricted Client')
    expect(html).to include('Name Redacted')
  end

  context 'a client who is not HMIS restricted' do
    let!(:window_data_source) { create(:visible_data_source) }
    let!(:destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Visible', LastName: 'Client') }
    let!(:source_client) { create(:window_hud_client, data_source_id: window_data_source.id, FirstName: 'Visible', LastName: 'Client') }
    let!(:warehouse_client) { create(:warehouse_client, source: source_client, destination: destination_client) }

    it 'redacts the client name when the requesting user has no role granting client visibility' do
      requesting_user = create(:user)

      html = render_history_pdf(client_id: destination_client.id, user_id: requesting_user.id)

      expect(html).not_to include('Visible Client')
      expect(html).to include('Name Redacted')
    end

    it 'shows the client name when the requesting user has a role granting client visibility' do
      requesting_user = create(:user)
      role = create(:role, can_view_clients: true, can_view_client_name: true)
      role.add(requesting_user)

      html = render_history_pdf(client_id: destination_client.id, user_id: requesting_user.id)

      expect(html).to include('Visible Client')
    end

    it 'shows the client name when there is no requesting user' do
      html = render_history_pdf(client_id: destination_client.id, user_id: 0)

      expect(html).to include('Visible Client')
    end
  end
end
