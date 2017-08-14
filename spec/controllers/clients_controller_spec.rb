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
      before { post :create_note, note: attributes_for(:grda_warehouse_client_notes_chronic_justification), id: client.id }
      
      it "creates client note" do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(1)
      end
      
      it "redirects to #show" do
        expect( response ).to redirect_to :action => :show
      end
      
      it "flashes notice" do
        expect(flash[:notice]).to be_present
      end
    end
    
    context "with invalid attributes" do
      before { post :create_note, note: { :note=>"" }, id: client.id } #invalid because note is an empty string
      
      it "does not save the new contact" do   
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(0)
      end
    
      it "re-renders #show" do
        expect( response ).to render_template :show
      end
      
      it "flashes error" do
        expect(flash[:error]).to be_present
      end
    end
  end
end
