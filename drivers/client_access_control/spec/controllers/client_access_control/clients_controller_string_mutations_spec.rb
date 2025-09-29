# frozen_string_literal: false

require 'rails_helper'

RSpec.describe ClientAccessControl::ClientsController, type: :controller do
  let(:user) { create(:user) }

  before(:each) do
    sign_in user
    allow(user).to receive(:can_access_some_client_search?).and_return(true)
    allow(user).to receive(:can_access_some_version_of_clients?).and_return(true)
    allow(user).to receive(:can_view_some_client_dashboard?).and_return(true)
    allow(user).to receive(:can_view_enrollment_details?).and_return(true)
  end

  describe '#assign_client_list_vars method with += operations' do
    it 'calls method that contains += operations for preloads array building' do
      # Test the += operations from lines 119-125 and 128-130: preloads += [...]

      # Mock clients relation
      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      # Mock pagy
      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])

      # Mock health_emergency? and healthcare_available? to trigger += operations
      allow(controller).to receive(:health_emergency?).and_return(true)
      allow(controller).to receive(:healthcare_available?).and_return(true)

      # Mock can_view_full_ssn?
      allow(controller).to receive(:can_view_full_ssn?).and_return(false)

      # Mock config
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(true)

      # Call the method that contains the += operations
      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      # Verify that preload was called with the accumulated arrays
      expect(clients).to have_received(:preload) do |preloads_array|
        # Should contain the base preloads plus health_emergency and healthcare additions
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:health_emergency_ama_restrictions)
        expect(preloads_array).to include(:health_emergency_triages)
        expect(preloads_array).to include(:health_emergency_tests)
        expect(preloads_array).to include(:health_emergency_isolations)
        expect(preloads_array).to include(:health_emergency_quarantines)
        expect(preloads_array).to include(:patient)
      end
    end

    it 'exercises += operations when health_emergency is true but healthcare is false' do
      # Test selective += operations based on conditions

      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])

      # Only health_emergency should trigger its += operation
      allow(controller).to receive(:health_emergency?).and_return(true)
      allow(controller).to receive(:healthcare_available?).and_return(false)

      allow(controller).to receive(:can_view_full_ssn?).and_return(false)
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(false)

      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      expect(clients).to have_received(:preload) do |preloads_array|
        # Should contain base preloads plus health_emergency items but not patient
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:health_emergency_ama_restrictions)
        expect(preloads_array).not_to include(:patient)
      end
    end

    it 'exercises += operations when healthcare is true but health_emergency is false' do
      # Test the other selective += operation

      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])

      # Only healthcare should trigger its += operation
      allow(controller).to receive(:health_emergency?).and_return(false)
      allow(controller).to receive(:healthcare_available?).and_return(true)

      allow(controller).to receive(:can_view_full_ssn?).and_return(false)
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(false)

      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      expect(clients).to have_received(:preload) do |preloads_array|
        # Should contain base preloads plus patient but not health_emergency items
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:patient)
        expect(preloads_array).not_to include(:health_emergency_ama_restrictions)
      end
    end

    it 'exercises += operations with neither condition true' do
      # Test that base preloads work without += operations

      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])

      # Neither condition should trigger += operations
      allow(controller).to receive(:health_emergency?).and_return(false)
      allow(controller).to receive(:healthcare_available?).and_return(false)

      allow(controller).to receive(:can_view_full_ssn?).and_return(false)
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(false)

      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      expect(clients).to have_received(:preload) do |preloads_array|
        # Should contain only base preloads
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:vispdats)
        expect(preloads_array).not_to include(:health_emergency_ama_restrictions)
        expect(preloads_array).not_to include(:patient)
      end
    end
  end

  describe 'controller actions that exercise string mutations' do
    it 'exercises index action that leads to assign_client_list_vars' do
      allow(GrdaWarehouse::ClientSearchQuery).to receive(:permit_params).and_return(nil)

      # Mock clients relation
      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)
      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])
      allow(controller).to receive(:health_emergency?).and_return(false)
      allow(controller).to receive(:healthcare_available?).and_return(false)

      expect { get :index }.not_to raise_error
    end

    it 'exercises search action that leads to assign_client_list_vars' do
      search_query = double('search_query', params: {}, touch: true)
      allow(GrdaWarehouse::ClientSearchQuery).to receive(:find_by).and_return(search_query)

      # Mock clients relation
      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)
      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])
      allow(controller).to receive(:health_emergency?).and_return(false)
      allow(controller).to receive(:healthcare_available?).and_return(false)

      expect { get :search, params: { id: 1 } }.not_to raise_error
    end

    it 'creates new instance without error' do
      controller_instance = ClientAccessControl::ClientsController.new

      expect(controller_instance).to be_a(ClientAccessControl::ClientsController)
    end
  end
end
