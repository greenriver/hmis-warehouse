require 'rails_helper'

# Here to explicitly include GrdaWarehouse::ClientNotes::Base before GrdaWarehouse::ClientNotes::ChronicJustification
RSpec.describe GrdaWarehouse::ClientNotes::Base, type: :model do
end

RSpec.describe GrdaWarehouse::ClientNotes::ChronicJustification, type: :model do
  
 
 
 describe 'validations' do 
   context 'if type is present' do
     let(:chronic_justification) { GrdaWarehouse::ClientNotes::ChronicJustification.new }
     
     it 'has type' do
       expect( chronic_justification.type_name ).to eq "Chronic Justification"
     end
   end
   
   context 'if note missing' do

     let(:chronic_justification) { build :grda_warehouse_client_notes_chronic_justification, note: nil }
     
     it 'is invalid' do
       expect( chronic_justification ).to be_invalid
     end
   end
  
 end
 
end
