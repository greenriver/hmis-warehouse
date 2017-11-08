require 'rails_helper'

RSpec.describe GrdaWarehouse::Vispdat, type: :model do
  
  let(:vispdat) { create :vispdat }

  context 'when updated' do
    context 'and completed is set' do

      before(:each) do
        vispdat.update( submitted_at: Time.now )
      end

      it 'queues an email' do
        expect( Delayed::Job.count ).to eq 1
      end
      it 'queues a vispdat complete email' do
        expect( Delayed::Job.first.payload_object.job_data['arguments'] ).to include "NotifyUser", "vispdat_completed"
      end

    end

    describe 'and completed already set' do
      
      let(:vispat) { create :vispdat, completed: Time.now }

      before(:each) do
        vispdat.update( nickname: 'Joey' )
      end

      it 'does not queue an email' do
        expect( Delayed::Job.count ).to eq 0
      end
    end
  end

end
