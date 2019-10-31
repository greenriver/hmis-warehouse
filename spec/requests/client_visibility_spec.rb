require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe ClientsController, type: :request do
  include_context 'visibility test context'

  context 'when config b is in affect' do
    let!(:config) { create :config_b }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        get clients_path(q: 'bob')
        expect(response).to redirect_to(new_user_session_path)
        # expect(response.body).to include('Sorry you are not authorized to do that.')
        # expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying all 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_client_window
        sign_in user
      end
      it 'user can see only window clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      it 'user can see client dashboard for window client' do
        get client_path(window_destination_client)
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for non-window client' do
        get client_path(non_window_destination_client)
        expect(response).to have_http_status(404)
      end
    end
    describe 'and the user has a role granting can search window' do
      before do
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see only window clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_see_clients_in_window_for_assigned_data_sources
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(0)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source' do
          expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(1)
          expect(GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id)).to eq([non_window_source_client.id])
        end
        describe 'and the user can search the window' do
          before do
            user.roles << can_search_window
          end
          it 'user can see clients visible in window and in data source' do
            expect(GrdaWarehouse::Hud::Client.viewable_by(user).count).to eq(2)
          end
        end
      end
    end
  end
end
