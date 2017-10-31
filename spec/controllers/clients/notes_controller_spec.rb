require 'rails_helper'
require_relative '../../../app/models/grda_warehouse/client_notes/base'
require_relative '../../../app/models/grda_warehouse/client_notes/chronic_justification'

RSpec.describe Clients::NotesController, type: :controller do
  let!(:admin) { create(:user) }
  let!(:admin_role) { create :admin_role }
  let!( :chronic_justification ) { create :grda_warehouse_client_notes_chronic_justification}
  let!(:initial_note_count) {GrdaWarehouse::ClientNotes::ChronicJustification.count}
  let!(:admin) { create(:user) }
  let!(:client) { create :grda_warehouse_hud_client }

  before do
    authenticate admin
    admin.roles << admin_role
  end
  
  describe 'DELETE #destroy' do

    it 'deletes the note' do 
      expect{ delete :destroy, id: chronic_justification, client_id: chronic_justification.client_id }.to change( GrdaWarehouse::ClientNotes::ChronicJustification, :count ).by( -1 )
    end
    
    it 'redirects to Client/#show' do
      delete :destroy, id: chronic_justification, client_id: chronic_justification.client_id
      expect( response ).to redirect_to( client_notes_path(chronic_justification.client_id ))
    end
  end

  describe "POST #create_note" do
    context "with valid attributes" do
      before do
        post :create, note: attributes_for(:grda_warehouse_client_notes_chronic_justification), client_id: client.id 
      end
      
      it "creates client note" do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count + 1)
      end
      
      it "redirects to #show" do
        expect( response ).to redirect_to(client_notes_path(client.id))
      end
      
      it "flashes notice" do
        expect(flash[:notice]).to be_present
      end
    end
    
    context "with invalid attributes" do
      before { post :create, note: { :note=>"" }, client_id: client.id } #invalid because note is an empty string
      
      it "does not save the new contact" do   
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count)
      end
    
      it "re-renders #show" do
        expect( response ).to redirect_to(client_notes_path(client.id))
      end
      
      it "flashes error" do
        expect(flash[:error]).to be_present
      end
    end
  end
end
