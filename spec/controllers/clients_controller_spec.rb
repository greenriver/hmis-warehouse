require 'rails_helper'
require_relative '../../app/models/grda_warehouse/client_notes/base'
require_relative '../../app/models/grda_warehouse/client_notes/chronic_justification'

RSpec.describe ClientsController, type: :controller do
  let!(:admin) { create(:user) }
  let!(:admin_role) { create :admin_role }
  let!(:client) { create :grda_warehouse_hud_client }
  
  before do
    authenticate admin
    admin.roles << admin_role
  end
  
  describe "POST #create_note" do
    context "with valid attributes" do
      it "creates client note" do
        note_params = attributes_for(:grda_warehouse_client_notes_chronic_justification)
        post :create_note, note: note_params, id: client.id 
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(1)
      end
      
      it "redirects to #show" do
        note_params = attributes_for(:grda_warehouse_client_notes_chronic_justification)
        post :create_note, note: note_params, id: client.id 
        
        expect( response ).to redirect_to :action => :show
      end
    end
    
    #TODO test for error messages 
    #TODO test for other types of invalid attributes
    context "with invalid attributes" do
      it "does not save the new contact" do 
        note_params = {:note=>""} #invalid because note is an empty string
        post :create_note, note: note_params, id: client.id 
        
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(0)
      end
      
      it "re-renders #show" do 
        note_params = {:note=>""} #invalid because note is an empty string
        post :create_note, note: note_params, id: client.id 
        
        expect( response ).to render_template :show
      end
    end
  end
end
