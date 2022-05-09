###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe ClientAccessControl::ClientsController, type: :request do
  include_context 'visibility test context'

  context 'when config b is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      AccessGroup.maintain_system_groups
    end
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
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
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
        expect(response).to redirect_to(user.my_root_path)
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
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can see directory information for window client' do
        get simple_client_path(window_source_client)
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  context 'when config s is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_s }
    let!(:user) { create :user }

    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        get clients_path(q: 'bob')
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe 'and the user has a role granting can view clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can search only window clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for window client' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can see client dashboard for window client with release' do
        past_date = 5.days.ago
        future_date = Date.current + 1.years
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: past_date,
          consent_expires_on: future_date,
        )
        get client_path(window_destination_client)
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for non-window client' do
        get client_path(non_window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
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
        expect(response).to redirect_to(user.my_root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
        describe 'user can see client data for assigned client' do
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
      end
    end
  end

  context 'when config 3c is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_3c }
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
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
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
        expect(response).to redirect_to(user.my_root_path)
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
        expect(response).to redirect_to(user.my_root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  context 'when config tc is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_tc }
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
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
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
        expect(response).to redirect_to(user.my_root_path)
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
        expect(response).to redirect_to(user.my_root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  context 'when config ma is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
      # Note, all data sources are visible in the window for ma
      non_window_visible_data_source.update(visible_in_window: true)
    end
    let!(:config) { create :config_ma }
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
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can see all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see only window clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for window client' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can see client dashboard for window client with release' do
        past_date = 5.days.ago
        future_date = Date.current + 1.years
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: past_date,
          consent_expires_on: future_date,
        )
        get client_path(window_destination_client)
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for non-window client' do
        get client_path(non_window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
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
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
        describe 'user can see client data for assigned client' do
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
      end
    end

    describe 'and the user has a role granting visibility by coc release' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can search for all clients' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 2 clients')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a CoC' do
        before do
          user.access_groups = []
          user.coc_codes = ['ZZ-999']
        end
        it 'user cannot see client details' do
          get client_path(non_window_destination_client)
          expect(response).to redirect_to(user.my_root_path)
        end
        describe 'when the client has a valid consent in any coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: [],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in the user\'s coc' do
          before do
            user.coc_codes = ['ZZ-999']
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999'],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in the user\'s coc and another coc' do
          before do
            user.coc_codes = ['ZZ-999']
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in another coc' do
          before do
            user.coc_codes = ['ZZ-999']
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['AA-000'],
            )
          end
          it 'user cannot see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
      end
    end
  end

  context 'when config mi is in effect' do
    before do
      GrdaWarehouse::Config.delete_all
      GrdaWarehouse::Config.invalidate_cache
    end
    let!(:config) { create :config_mi }
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
        AccessGroup.where(name: 'All Data Sources').first.users << user
        sign_in user
      end
      it 'user can not search for clients' do
        get clients_path(q: 'bob')
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can see any clients' do
        get client_path(non_window_destination_client)
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Bob Ross')
        expect(response).to have_http_status(200)
      end
    end
    describe 'and the user has a role granting can view window clients' do
      before do
        user.roles << can_view_clients
        sign_in user
      end
      it 'user can not search for clients' do
        get clients_path(q: 'bob')
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user cannot see client dashboard for window client' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can see client dashboard for window client with release' do
        past_date = 5.days.ago
        future_date = Date.current + 1.years
        window_destination_client.update(
          housing_release_status: window_destination_client.class.full_release_string,
          consent_form_signed_on: past_date,
          consent_expires_on: future_date,
        )
        get client_path(window_destination_client)
        expect(response).to have_http_status(200)
      end
      it 'user cannot see client dashboard for non-window client' do
        get client_path(non_window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
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
        expect(response).to redirect_to(user.my_root_path)
      end
    end
    describe 'and the user has a role granting visibility by data source' do
      before do
        user.roles << can_view_clients
        user.roles << can_search_window
        sign_in user
      end
      it 'user can see window clients in search results' do
        get clients_path(q: 'bob')
        doc = Nokogiri::HTML(response.body)
        expect(doc.text).to include('Displaying 1 client')
        expect(response).to have_http_status(200)
      end
      describe 'and the user is assigned a data source' do
        before do
          user.add_viewable(non_window_visible_data_source)
        end
        it 'user can see one client in expected data source and any window clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying 2 clients')
          expect(response).to have_http_status(200)
        end
        describe 'user can see client data for assigned client' do
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
      end
    end

    describe 'and the user has a role granting visibility by coc release' do
      before do
        user.roles << can_view_clients
        sign_in user
      end
      it 'user can not search for all clients' do
        get clients_path(q: 'bob')
        expect(response).to redirect_to(user.my_root_path)
      end
      it 'user can not see directory information for window client (search is required)' do
        get simple_client_path(window_source_client)
        expect(response).to redirect_to(user.my_root_path)
      end
      describe 'and the user is assigned a CoC' do
        before do
          user.coc_codes = ['ZZ-999']
        end
        it 'user cannot see client details' do
          get client_path(non_window_destination_client)
          expect(response).to redirect_to(user.my_root_path)
        end
        describe 'when the client has a valid consent in any coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: [],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in the user\'s coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999'],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in the user\'s coc and another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
          end
          it 'user can see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
        describe 'when the client has a valid consent in another coc' do
          before do
            past_date = 5.days.ago
            future_date = Date.current + 1.years
            non_window_destination_client.update(
              housing_release_status: non_window_destination_client.class.full_release_string,
              consent_form_signed_on: past_date,
              consent_expires_on: future_date,
              consented_coc_codes: ['AA-000'],
            )
          end
          it 'user cannot see client dashboard for assigned client' do
            get client_path(non_window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
          it 'user cannot see client dashboard for window client' do
            get client_path(window_destination_client)
            expect(response).to redirect_to(user.my_root_path)
          end
        end
      end
    end
  end
end
