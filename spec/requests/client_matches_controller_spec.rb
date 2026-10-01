###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientMatchesController, type: :request do
  describe '#index' do
    context 'when a matched client name contains markup' do
      let(:destination_ds) { create(:destination_data_source) }
      let(:source_ds) { create(:visible_data_source) }
      let(:user) { create(:user) }

      let(:existing_source) { create(:hud_client, FirstName: 'Existing', LastName: 'Client', data_source_id: source_ds.id) }
      let(:existing_destination) { create(:hud_client, data_source_id: destination_ds.id) }
      let(:proposed_source) { create(:hud_client, FirstName: '<script>alert(1)</script>', LastName: 'Proposed', data_source_id: source_ds.id) }
      let(:proposed_destination) { create(:hud_client, data_source_id: destination_ds.id) }

      before do
        user.legacy_roles << create(:can_edit_clients)
        user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
        GrdaWarehouse::WarehouseClient.create!(destination_id: existing_destination.id, source_id: existing_source.id, id_in_source: existing_source.PersonalID)
        GrdaWarehouse::WarehouseClient.create!(destination_id: proposed_destination.id, source_id: proposed_source.id, id_in_source: proposed_source.PersonalID)
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: existing_source.id, source_client_id: proposed_source.id, score: -5.0)
        sign_in user
      end

      it 'escapes a client full name embedded in the accept-tooltip markup, rather than injecting it verbatim' do
        get client_matches_path

        expect(response.body).not_to include('<script>alert(1)</script>')
        expect(response.body).to include(CGI.escapeHTML('<script>alert(1)</script>'))
      end

      it 'renders the accept-tooltip as plain text rather than opting into HTML rendering' do
        get client_matches_path

        accept_link = Nokogiri::HTML(response.body).at_css('a[data-bs-toggle="tooltip"][data-bs-title]')
        expect(accept_link['data-bs-html']).to be_nil
      end

      it 'renders the accept-tooltip without error when a matched client has no name on file' do
        blank_name_source = create(:hud_client, data_source_id: source_ds.id)
        blank_name_destination = create(:hud_client, data_source_id: destination_ds.id)
        GrdaWarehouse::WarehouseClient.create!(destination_id: blank_name_destination.id, source_id: blank_name_source.id, id_in_source: blank_name_source.PersonalID)
        GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: blank_name_source.id, source_client_id: proposed_source.id, score: -5.0)

        get client_matches_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("into existing:\n #{blank_name_source.uuid}")
      end
    end

    context 'when a matched client is restricted' do
      let!(:user) { create(:acl_user) }
      let!(:role) { create(:role, can_edit_clients: true, can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true) }
      let!(:collection) { Collection.system_collection(:data_sources) }

      let!(:hmis_ds) { create(:hmis_primary_data_source) }
      let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client', ssn: '111223333', dob: '1980-01-01') }
      let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
      let!(:candidate_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Candidate', LastName: 'Client') }
      let!(:candidate_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Candidate', last_name: 'Client', ssn: '444556666', dob: '1985-06-15') }
      let!(:match) do
        GrdaWarehouse::ClientMatch.create!(
          destination_client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id),
          source_client: GrdaWarehouse::Hud::Client.find(candidate_source_client.id),
          status: 'candidate',
          # `_client_match.haml` renders `match.score.round(2).abs` unconditionally.
          score: -1.0,
        )
      end

      before do
        Collection.maintain_system_groups
        setup_access_control(user, role, collection)
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination_client.id, source_id: candidate_source_client.id, data_source_id: hmis_ds.id, id_in_source: candidate_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        sign_in user
      end

      it 'redacts the restricted destination client name in the match heading' do
        get client_matches_path

        expect(response.body).not_to include('Restricted Client')
        expect(response.body).to include('Name Redacted')
      end

      it 'redacts the restricted client name, SSN, and DOB in the match card' do
        get client_matches_path

        expect(response.body).not_to include('111-22-3333')
        expect(response.body).not_to include('Jan  1, 1980')
      end

      it 'shows the unrestricted candidate client name, SSN, and DOB in the match card' do
        get client_matches_path

        expect(response.body).to include('Candidate Client')
        expect(response.body).to include('444-55-6666')
        expect(response.body).to include('Jun 15, 1985')
      end
    end
  end
end
