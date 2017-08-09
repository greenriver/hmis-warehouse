require 'rails_helper'
require_relative '../../../app/models/grda_warehouse/client_notes/base'
require_relative '../../../app/models/grda_warehouse/client_notes/chronic_justification'

RSpec.describe Clients::NotesController, type: :controller do
  let!(:admin) { FactoryGirl.create(:user) }
  let!(:admin_role) { create :admin_role }
  
  let!( :chronic_justification ) { create :grda_warehouse_client_notes_chronic_justification}
  
  before do
    authenticate admin
    admin.roles << admin_role
  end
  
  describe 'DELETE #destroy' do

    it 'deletes the note' do 
      expect{ delete :destroy, id: chronic_justification }.to change( GrdaWarehouse::ClientNotes::ChronicJustification, :count ).by( -1 )
    end
    
    it 'redirects to Client/#show' do
      client = chronic_justification.client_id
      delete :destroy, id: chronic_justification
      # binding.pry
      expect( response ).to redirect_to( client_path(chronic_justification.client_id ))
    end
  end
end
