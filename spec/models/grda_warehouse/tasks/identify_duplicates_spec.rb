require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::IdentifyDuplicates, type: :model do
  let(:source_data_source) { create :source_data_source }
  let(:destination_data_source) { create :grda_warehouse_data_source }

  let!(:client_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
  let!(:client_in_destination) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  it 'recognizes an obvious match' do
    expect(check_for_obvious_match(client_in_source.id)).to be client_in_destination.id
  end

  describe 'obvious match processing with a split' do
    let!(:split) { create :grda_warehouse_client_split_history, split_from: client_in_source.id, split_into: client_in_destination.id }

    it 'does not return an obvious match if it was split' do
      expect(check_for_obvious_match(client_in_source.id)).to be_nil
    end
  end

  describe 'find merge candidates' do
    let!(:client_two_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
    let!(:warehouse_data_source) { create :destination_data_source }

    before(:each) do
      processor = GrdaWarehouse::Tasks::IdentifyDuplicates.new(test: true)
      processor.run!
      processor.match_existing!
    end

    it 'merged client and client 2 into a single destination client' do
      expect(client_in_source.destination_client.id).to eq(client_two_in_source.destination_client.id)
      expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
    end

    describe 'merge processing after a split' do
      let(:user) { create :user }

      before(:each) do
        destination_client = client_in_source.destination_client
        split_client_id = destination_client.source_clients.last.id
        destination_client.split(
          [split_client_id],
          destination_client.id,
          destination_client.id,
          user,
        )
      end

      it 'sees two destination clients after split' do
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
      end

      it 'does not re-merge the split clients' do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new(test: true).match_existing!

        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
      end
    end
  end

  # Check for obvious match is private...
  def check_for_obvious_match(client_id)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.send(:check_for_obvious_match, client_id)
  end
end
