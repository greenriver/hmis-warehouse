require 'rails_helper'
require_relative '../../../app/models/grda_warehouse/client_notes/base'
require_relative '../../../app/models/grda_warehouse/client_notes/chronic_justification'

RSpec.describe Clients::NotesController, type: :request do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  let!(:admin) { create :user }
  let!(:admin_role) { create :admin_role }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }
  let!(:chronic_justification) { create :grda_warehouse_client_notes_chronic_justification, client: client }
  let!(:initial_note_count) { GrdaWarehouse::ClientNotes::ChronicJustification.count }
  let!(:no_data_source_access_group) { create :access_group }

  before do
    sign_in admin
    AccessGroup.maintain_system_groups
    setup_access_control(admin, admin_role, AccessGroup.system_access_group(:data_sources))
  end

  describe 'DELETE #destroy' do
    it 'deletes the note' do
      expect { delete client_note_path(chronic_justification.client, chronic_justification) }.to change(GrdaWarehouse::ClientNotes::ChronicJustification, :count).by(-1)
    end

    it 'redirects to Client/#show' do
      delete client_note_path(chronic_justification.client, chronic_justification)
      expect(response).to redirect_to(client_notes_path(chronic_justification.client.id))
    end
  end

  describe 'POST #create_note' do
    context 'with valid attributes' do
      before do
        post client_notes_path(client), params: { note: attributes_for(:grda_warehouse_client_notes_chronic_justification) }
      end

      it 'creates client note' do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count + 1)
      end

      it 'redirects to #show' do
        expect(response).to redirect_to(client_notes_path(client.id))
      end

      it 'flashes notice' do
        expect(flash[:notice]).to be_present
      end
    end

    context 'with invalid attributes' do
      before { post client_notes_path(client), params: { note: { note: '' } } } # invalid because note is an empty string

      it 'does not save the new contact' do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count)
      end

      it 're-renders #show' do
        expect(response).to redirect_to(client_notes_path(client.id))
      end

      it 'flashes error' do
        expect(flash[:error]).to be_present
      end
    end
  end
end
