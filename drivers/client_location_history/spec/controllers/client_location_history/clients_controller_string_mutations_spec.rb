# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientLocationHistory::ClientsController, type: :controller do
  let(:user) { create(:user) }
  let(:client) { create(:grda_warehouse_hud_client) }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_view_clients?).and_return(true)
    allow(user).to receive(:can_view_client_locations?).and_return(true)
    allow(controller).to receive(:set_client) { controller.instance_variable_set(:@client, client) }
  end

  describe '#map method with += operations' do
    it 'calls method that contains += operations for client_ids array building' do
      # Test the += operation from line 23: client_ids += ::GrdaWarehouse::Hud::Client.source_visible_to(...).pluck(:id)

      # Mock the client to be a destination client
      allow(client).to receive(:id).and_return(123)
      allow(client).to receive(:destination?).and_return(true)
      allow(client).to receive(:source_client_ids).and_return([456, 789])

      # Mock the source client query and result
      source_client_scope = double('source_client_scope')
      allow(::GrdaWarehouse::Hud::Client).to receive(:source_visible_to).and_return(source_client_scope)
      allow(source_client_scope).to receive(:where).and_return(source_client_scope)
      allow(source_client_scope).to receive(:pluck).with(:id).and_return([456, 789])

      # Mock location and marker related objects
      locations = []
      allow(ClientLocationHistory::Location).to receive(:where).and_return(locations)
      allow(locations).to receive(:map).and_return([])
      allow(ClientLocationHistory::Location).to receive(:bounds).and_return({})
      allow(ClientLocationHistory::Location).to receive(:highlight).and_return([])

      # Mock the filter
      filter = double('filter', range: Date.current..Date.current)
      allow(controller).to receive(:filter).and_return(filter)

      # Call the method that contains the += operation
      expect { get :map, params: { id: client.id } }.not_to raise_error
    end

    it 'exercises += operation when client is destination with source clients' do
      # Test the actual += accumulation with specific values

      allow(client).to receive(:id).and_return(100)
      allow(client).to receive(:destination?).and_return(true)
      allow(client).to receive(:source_client_ids).and_return([200, 300])

      # Mock source clients to return specific IDs for += operation
      source_client_scope = double('source_client_scope')
      allow(::GrdaWarehouse::Hud::Client).to receive(:source_visible_to).and_return(source_client_scope)
      allow(source_client_scope).to receive(:where).and_return(source_client_scope)
      allow(source_client_scope).to receive(:pluck).with(:id).and_return([200, 300])

      # Mock location queries to verify the accumulated client_ids are used
      locations = []
      allow(ClientLocationHistory::Location).to receive(:where) do |conditions|
        # Should receive the accumulated client_ids: [100] + [200, 300] = [100, 200, 300]
        expect(conditions[:client_id]).to contain_exactly(100, 200, 300)
        locations
      end

      allow(locations).to receive(:map).and_return([])
      allow(ClientLocationHistory::Location).to receive(:bounds).and_return({})
      allow(ClientLocationHistory::Location).to receive(:highlight).and_return([])

      filter = double('filter', range: Date.current..Date.current)
      allow(controller).to receive(:filter).and_return(filter)

      # This will exercise the += operation and verify the result is used correctly
      expect { get :map, params: { id: client.id } }.not_to raise_error
    end

    it 'skips += operation when client is not destination' do
      # Test that += operation is conditional on client.destination?

      allow(client).to receive(:id).and_return(500)
      allow(client).to receive(:destination?).and_return(false)

      # Mock location queries to verify only the base client_id is used
      locations = []
      allow(ClientLocationHistory::Location).to receive(:where) do |conditions|
        # Should only receive the base client_id: [500], no += operation
        expect(conditions[:client_id]).to eq([500])
        locations
      end

      allow(locations).to receive(:map).and_return([])
      allow(ClientLocationHistory::Location).to receive(:bounds).and_return({})
      allow(ClientLocationHistory::Location).to receive(:highlight).and_return([])

      filter = double('filter', range: Date.current..Date.current)
      allow(controller).to receive(:filter).and_return(filter)

      # Should NOT call the source_visible_to query since destination? is false
      allow(::GrdaWarehouse::Hud::Client).to receive(:source_visible_to)

      expect { get :map, params: { id: client.id } }.not_to raise_error

      # Verify += operation was skipped
      expect(::GrdaWarehouse::Hud::Client).not_to have_received(:source_visible_to)
    end

    it 'handles empty source client results with += operation' do
      # Test += operation with empty array

      allow(client).to receive(:id).and_return(600)
      allow(client).to receive(:destination?).and_return(true)
      allow(client).to receive(:source_client_ids).and_return([])

      source_client_scope = double('source_client_scope')
      allow(::GrdaWarehouse::Hud::Client).to receive(:source_visible_to).and_return(source_client_scope)
      allow(source_client_scope).to receive(:where).and_return(source_client_scope)
      allow(source_client_scope).to receive(:pluck).with(:id).and_return([])

      # Should still get the base client_id even with empty += result
      locations = []
      allow(ClientLocationHistory::Location).to receive(:where) do |conditions|
        expect(conditions[:client_id]).to eq([600])
        locations
      end

      allow(locations).to receive(:map).and_return([])
      allow(ClientLocationHistory::Location).to receive(:bounds).and_return({})
      allow(ClientLocationHistory::Location).to receive(:highlight).and_return([])

      filter = double('filter', range: Date.current..Date.current)
      allow(controller).to receive(:filter).and_return(filter)

      expect { get :map, params: { id: client.id } }.not_to raise_error
    end
  end

  describe 'controller methods that exercise string mutations' do
    it 'exercises client_scope method without mutations' do
      allow(::GrdaWarehouse::Hud::Client).to receive(:destination_visible_to).and_return(::GrdaWarehouse::Hud::Client)
      allow(::GrdaWarehouse::Hud::Client).to receive(:where).and_return(::GrdaWarehouse::Hud::Client)

      controller.send(:client_scope, id: 123)

      expect(::GrdaWarehouse::Hud::Client).to have_received(:destination_visible_to).with(user)
      expect(::GrdaWarehouse::Hud::Client).to have_received(:where).with(id: 123)
    end

    it 'creates new instance without error' do
      controller_instance = ClientLocationHistory::ClientsController.new

      expect(controller_instance).to be_a(ClientLocationHistory::ClientsController)
    end
  end
end
