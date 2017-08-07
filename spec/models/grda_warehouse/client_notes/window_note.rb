require 'rails_helper'

# Here to explicitly include GrdaWarehouse::ClientNotes::Base before GrdaWarehouse::ClientNotes::ChronicJustification
RSpec.describe GrdaWarehouse::ClientNotes::Base, type: :model do
end

RSpec.describe GrdaWarehouse::ClientNotes::WindowNote, type: :model do
  
 
 
 describe 'validations' do 
   context 'if type is present' do
     let(:window_note) { GrdaWarehouse::ClientNotes::WindowNote.new }
     
     it 'has type' do
       expect( window_note.type_name ).to eq "Chronic Justification"
     end
   end
   
   context 'if note missing' do

     let(:window_note) { build :grda_warehouse_client_notes_window_note, note: nil }
     
     it 'is invalid' do
       expect( window_note ).to be_invalid
     end
   end
  
 end
 
end
