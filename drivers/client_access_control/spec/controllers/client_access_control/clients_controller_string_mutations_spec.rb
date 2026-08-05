###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
    it 'includes health emergency preloads when health_emergency? is true' do
      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])
      allow(controller).to receive(:health_emergency?).and_return(true)
      allow(controller).to receive(:can_view_full_ssn?).and_return(false)
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(true)

      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      expect(clients).to have_received(:preload) do |preloads_array|
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:health_emergency_ama_restrictions)
        expect(preloads_array).to include(:health_emergency_triages)
        expect(preloads_array).to include(:health_emergency_tests)
        expect(preloads_array).to include(:health_emergency_isolations)
        expect(preloads_array).to include(:health_emergency_quarantines)
      end
    end

    it 'omits health emergency preloads when health_emergency? is false' do
      clients = double('clients')
      allow(clients).to receive(:destination).and_return(clients)
      allow(clients).to receive(:preload).and_return(clients)

      allow(controller).to receive(:pagy).and_return([double('pagy'), clients])
      allow(controller).to receive(:health_emergency?).and_return(false)
      allow(controller).to receive(:can_view_full_ssn?).and_return(false)
      allow(GrdaWarehouse::Config).to receive(:get).with(:show_partial_ssn_in_window_search_results).and_return(false)

      expect { controller.send(:assign_client_list_vars, clients) }.not_to raise_error

      expect(clients).to have_received(:preload) do |preloads_array|
        expect(preloads_array).to include(:processed_service_history)
        expect(preloads_array).to include(:vispdats)
        expect(preloads_array).not_to include(:health_emergency_ama_restrictions)
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

      expect { get :search, params: { id: 1 } }.not_to raise_error
    end

    it 'creates new instance without error' do
      controller_instance = ClientAccessControl::ClientsController.new

      expect(controller_instance).to be_a(ClientAccessControl::ClientsController)
    end
  end
end
