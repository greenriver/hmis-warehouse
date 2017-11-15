require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do  
  let(:client) { build :grda_warehouse_hud_client }

  context 'when created' do
    before(:each) do
      client
    end
    context 'and send_notifications true' do
      it 'queues a notify job' do
        client.send_notifications = true
        client.save
        expect( Delayed::Job.count ).to eq 1
      end
    end
    context 'and send_notifications false' do
      it 'does not queue a notify job' do
        client.send_notifications = false
        client.save
        expect( Delayed::Job.count ).to eq 0
      end
    end
  end
end
