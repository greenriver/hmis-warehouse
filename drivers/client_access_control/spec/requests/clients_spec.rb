###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'
require_relative '../support/client_search_context'

RSpec.describe ClientAccessControl::ClientsController, type: :request do
  include_context 'visibility test context'
  include_context 'client search helpers'

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }

  before do
    Collection.maintain_system_groups
  end

  describe 'logged out' do
    it 'doesn\'t allow index' do
      get clients_path
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow search results' do
      query = create(:grda_warehouse_client_search_query)
      get client_search_query_path(id: query.id)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow show' do
      get client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow new' do
      get new_client_path
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow create' do
      post clients_path
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow edit' do
      get edit_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow service_range' do
      get service_range_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow rollup' do
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow assessment' do
      get assessment_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow image' do
      get image_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow chronic_days' do
      get chronic_days_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow merge' do
      patch merge_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end

    it 'doesn\'t allow unmerge' do
      patch unmerge_client_path(window_destination_client)
      expect(response).to redirect_to(regex_for_warehouse_sign_in)
    end
  end

  describe 'logged in, no permissions' do
    # FIXME: find_client in the controller 404s when there are no data sources visible in the window

    it 'doesn\'t allow index' do
      sign_in user
      get clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow search results' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, created_by: user)
      get client_search_query_path(id: query.id)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(window_destination_client, format: :json)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(window_destination_client, format: :json)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end
  end

  describe 'logged in, and can search window' do
    before do
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end

    it 'allows index with no params' do
      sign_in user
      get clients_path
      expect(response).to render_template(:index)
    end

    it 'handles legacy GET search request' do
      sign_in user
      get clients_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'handles POST search request' do
      sign_in user
      post client_search_queries_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'reuses existing search query for same params' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'test' })
      post client_search_queries_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(query.id.to_s)
    end

    it 'allows viewing search results' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'test' })
      original_updated_at = query.updated_at
      travel 1.hour do
        get client_search_query_path(id: query.id)
        expect(response).to have_http_status(200)
        expect(query.reload.updated_at).to be > original_updated_at
      end
    end

    it 'handles text search' do
      sign_in user
      post client_search_queries_path, params: { q: 'test' }
      follow_redirect!
      expect(response).to have_http_status(200)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(window_destination_client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(window_destination_client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end
  end

  describe 'logged in, and can use strict search' do
    before do
      setup_access_control(user, can_use_strict_search, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end

    it 'handles strict search params' do
      sign_in user
      post client_search_queries_path, params: {
        client: {
          first_name: 'John',
          last_name: 'Doe',
          dob: '1990-01-01',
          ssn: '123456789',
        },
      }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'renders strict search template' do
      sign_in user
      query = create(
        :grda_warehouse_client_search_query,
        params: { client: { first_name: 'John', last_name: 'Doe' } },
      )
      get client_search_query_path(id: query.id)
      expect(response).to render_template('strict_search')
    end
  end

  describe 'logged in, and can view client window' do
    before do
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'handles search request' do
      sign_in user
      post client_search_queries_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'allows viewing search results' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, params: { q: 'test' })
      get client_search_query_path(id: query.id)
      expect(response).to have_http_status(200)
    end

    it 'allows show' do
      sign_in user
      get client_path(window_destination_client)
      expect(response).to render_template(:show)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows service_range' do
      sign_in user
      get service_range_client_path(window_destination_client, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allows rollup' do
      sign_in user
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to render_template('clients/rollup/_residential_enrollments')
    end

    # through can_see_this_client_demographics
    it 'allows assessment' do
      sign_in user
      form = window_source_client.hmis_forms.create(data_source_id: window_source_client.data_source_id)
      get assessment_client_path(form, client_id: window_destination_client.id)
      expect(response).to have_http_status(200)
    end

    it 'allows image' do
      sign_in user
      get image_client_path(window_destination_client)
      expect(response).to have_http_status(403)
    end

    it 'allows chronic_days' do
      sign_in user
      get chronic_days_client_path(window_destination_client, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end
  end

  describe 'logged in, and can edit clients' do
    before do
      setup_access_control(user, can_edit_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'handles search request' do
      sign_in user
      post client_search_queries_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'allows viewing search results' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, params: { q: 'test' })
      get client_search_query_path(id: query.id)
      expect(response).to have_http_status(200)
    end

    it 'allows show' do
      sign_in user
      get client_path(window_destination_client)
      expect(response).to render_template(:show)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows edit' do
      sign_in user
      get edit_client_path(window_destination_client)
      expect(response).to render_template(:edit)
    end

    it 'allows service_range' do
      sign_in user
      get service_range_client_path(window_destination_client, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allows rollup' do
      sign_in user
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to render_template('clients/rollup/_residential_enrollments')
    end

    # through can_see_this_client_demographics
    it 'allows assessment' do
      sign_in user
      form = window_source_client.hmis_forms.create(data_source_id: window_source_client.data_source_id)
      get assessment_client_path(form, client_id: window_destination_client.id)
      expect(response).to have_http_status(200)
    end

    it 'allows image' do
      sign_in user
      get image_client_path(window_destination_client)
      expect(response).to have_http_status(403)
    end

    it 'allows chronic_days' do
      sign_in user
      get chronic_days_client_path(window_destination_client, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allow merge' do
      sign_in user
      patch merge_client_path(window_destination_client, grda_warehouse_hud_client: { merge: [''] })
      expect(response).to redirect_to(edit_client_path(window_destination_client.id))
    end

    it 'allow unmerge' do
      sign_in user
      patch unmerge_client_path(window_destination_client, grda_warehouse_hud_client: { unmerge: [''] })
      expect(response).to redirect_to(edit_client_path(window_destination_client.id))
    end
  end

  describe 'logged in, and can create clients' do
    before do
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_create_clients, Collection.system_collection(:window_data_sources))
    end

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'handles search request' do
      sign_in user
      post client_search_queries_path, params: { q: 'test' }
      redirect_id = extract_redirect_id(response)
      expect(redirect_id).to eq(GrdaWarehouse::ClientSearchQuery.sole.id.to_s)
    end

    it 'allows viewing search results' do
      sign_in user
      query = create(:grda_warehouse_client_search_query, params: { q: 'test' })
      get client_search_query_path(id: query.id)
      expect(response).to have_http_status(200)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows new' do
      sign_in user
      get new_client_path
      expect(response).to render_template(:new)
    end

    it 'allows create' do
      sign_in user
      post clients_path(client: { data_source_id: window_visible_data_source.id, SSN: '123456789', FirstName: 'New First', LastName: 'New Last', DOB: '2019-09-16', PersonalID: '1234' })
      expect(GrdaWarehouse::Hud::Client.source.where(FirstName: 'New First', LastName: 'New Last').count).to eq(1)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(window_destination_client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(window_destination_client, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(window_destination_client)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(window_destination_client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(window_destination_client)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end
  end

  describe 'dashboard permission enforcement' do
    let!(:can_view_full_client_dashboard) { create :role, can_view_full_client_dashboard: true, can_view_client_name: true }
    let!(:can_view_limited_client_dashboard) { create :role, can_view_limited_client_dashboard: true, can_view_client_name: true }

    context 'when user can view clients but has no dashboard permissions' do
      # Remove can_view_limited_client_dashboard from can_view_clients role, we set it in the shared context
      # to keep other tests working
      let!(:can_view_clients_only) { create :role, can_view_clients: true, can_view_client_name: true, can_view_limited_client_dashboard: false }

      before do
        setup_access_control(user, can_view_clients_only, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        sign_in user
      end

      it 'blocks access to client show page' do
        get client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end

      it 'blocks access to service_range' do
        get service_range_client_path(window_destination_client, format: :json)
        expect(response).to redirect_to(user.my_root_path)
      end

      it 'blocks access to rollup' do
        get rollup_client_path(window_destination_client, partial: :residential_enrollments)
        expect(response).to redirect_to(user.my_root_path)
      end

      it 'blocks access to image' do
        get image_client_path(window_destination_client)
        expect(response).to redirect_to(user.my_root_path)
      end
    end

    context 'when user can view clients and has full dashboard permission' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_full_client_dashboard, Collection.system_collection(:window_data_sources))
        sign_in user
      end

      it 'allows access to client show page' do
        get client_path(window_destination_client)
        expect(response).to render_template(:show)
      end

      it 'allows access to service_range' do
        get service_range_client_path(window_destination_client, format: :json)
        expect(response).to have_http_status(200)
      end

      it 'allows access to rollup' do
        get rollup_client_path(window_destination_client, partial: :residential_enrollments)
        expect(response).to render_template('clients/rollup/_residential_enrollments')
      end

      it 'allows access to image (test env always returns 403)' do
        # Mock the pii provider to return an image, we're not testing the pii provider
        mock_pii_provider = instance_double(GrdaWarehouse::PiiProvider)
        allow(mock_pii_provider).to receive(:image?).and_return(true)
        allow(mock_pii_provider).to receive(:image).and_return('test')
        allow(window_destination_client).to receive(:pii_provider).and_return(mock_pii_provider)

        get image_client_path(window_destination_client)
        expect(response).to have_http_status(403)
      end
    end

    context 'when user can view clients and has limited dashboard permission' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
        setup_access_control(user, can_view_limited_client_dashboard, Collection.system_collection(:window_data_sources))
        sign_in user
      end

      it 'allows access to client show page' do
        get client_path(window_destination_client)
        expect(response).to render_template(:show)
      end

      it 'allows access to service_range' do
        get service_range_client_path(window_destination_client, format: :json)
        expect(response).to have_http_status(200)
      end

      it 'allows access to rollup' do
        get rollup_client_path(window_destination_client, partial: :residential_enrollments)
        expect(response).to render_template('clients/rollup/_residential_enrollments')
      end

      it 'allows access to image (test env always returns 403)' do
        # Mock the pii provider to return an image, we're not testing the pii provider
        mock_pii_provider = instance_double(GrdaWarehouse::PiiProvider)
        allow(mock_pii_provider).to receive(:image?).and_return(true)
        allow(mock_pii_provider).to receive(:image).and_return('test')
        allow(window_destination_client).to receive(:pii_provider).and_return(mock_pii_provider)

        get image_client_path(window_destination_client)
        expect(response).to have_http_status(403)
      end
    end

    context 'client_dashboard config variants' do
      variants = {
        default: {
          dispatcher: 'client_access_control/clients/_default',
          full_rollup: 'client_access_control/clients/_rollups',
          limited_rollup: 'client_access_control/clients/_rollups_limited',
        },
        va: {
          dispatcher: 'client_access_control/clients/_va',
          full_rollup: 'client_access_control/clients/va/_rollups',
          limited_rollup: 'client_access_control/clients/va/_rollups',
        },
        boston: {
          dispatcher: 'client_access_control/clients/_boston',
          full_rollup: 'client_access_control/clients/boston/_rollups',
          limited_rollup: 'client_access_control/clients/boston/_rollups_limited',
        },
      }

      variants.each do |variant, templates|
        context "when client_dashboard config is #{variant}" do
          before { config.update(client_dashboard: variant) }

          it 'renders the full rollups partial for a user with full dashboard permission' do
            setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_view_full_client_dashboard, Collection.system_collection(:window_data_sources))
            sign_in user

            get client_path(window_destination_client)

            expect(response).to render_template(templates[:dispatcher])
            expect(response).to render_template(templates[:full_rollup])
          end

          it 'renders the limited rollups partial for a user with limited dashboard permission' do
            setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
            setup_access_control(user, can_view_limited_client_dashboard, Collection.system_collection(:window_data_sources))
            sign_in user

            get client_path(window_destination_client)

            expect(response).to render_template(templates[:dispatcher])
            expect(response).to render_template(templates[:limited_rollup])
          end
        end
      end
    end

    context 'boston assessments_with_limited_data rollup' do
      # NOTE: the shared context's `can_view_clients` role bakes in `can_view_limited_client_dashboard: true`,
      # so these roles are self-contained rather than layered on top of it, to keep full-vs-limited meaningful.
      let!(:limited_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: false, can_view_limited_client_dashboard: true }
      let!(:full_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: true, can_view_limited_client_dashboard: false }

      def build_pathways_assessment(date: Date.current)
        assessment = create(:hud_assessment, data_source_id: window_visible_data_source.id, PersonalID: window_source_client.PersonalID, EnrollmentID: window_enrollment.EnrollmentID, AssessmentDate: date)
        GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: assessment.AssessmentID.to_s, response_text: 'Pathways 2024')
        create(
          :hud_assessment_question,
          data_source_id: window_visible_data_source.id,
          AssessmentID: assessment.AssessmentID,
          AssessmentQuestion: 'c_housing_assessment_name',
          AssessmentAnswer: assessment.AssessmentID.to_s,
        )
        assessment
      end

      let!(:pathways_assessment) { build_pathways_assessment }
      let!(:non_qualifying_assessment) do
        create(:hud_assessment, data_source_id: window_visible_data_source.id, PersonalID: window_source_client.PersonalID, EnrollmentID: window_enrollment.EnrollmentID, AssessmentLevel: 2)
      end

      it 'shows a link to the pathways assessment when config is boston and the user has limited dashboard permission' do
        config.update(client_dashboard: :boston)
        setup_access_control(user, limited_dashboard_role, Collection.system_collection(:window_data_sources))
        sign_in user

        get rollup_client_path(window_destination_client, partial: :boston_assessments_with_limited_data)

        expect(response.body).to include(client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment))
      end

      it 'shows a row for a non-qualifying assessment without a link to it, alongside the linked pathways assessment' do
        config.update(client_dashboard: :boston)
        setup_access_control(user, limited_dashboard_role, Collection.system_collection(:window_data_sources))
        sign_in user

        get rollup_client_path(window_destination_client, partial: :boston_assessments_with_limited_data)

        expect(response.body).to include(client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment))
        expect(response.body).to include(non_qualifying_assessment.name)
        expect(response.body).not_to include(client_coordinated_entry_hud_assessment_path(window_destination_client, non_qualifying_assessment))
      end

      it 'collapses multiple assessments of the same type, showing the newest by default with a toggle to expand' do
        older_pathways_assessment = build_pathways_assessment(date: 6.months.ago.to_date)
        config.update(client_dashboard: :boston)
        setup_access_control(user, limited_dashboard_role, Collection.system_collection(:window_data_sources))
        sign_in user

        get rollup_client_path(window_destination_client, partial: :boston_assessments_with_limited_data)

        doc = Nokogiri::HTML(response.body)
        newer_link = doc.at_css("a[href='#{client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment)}']")
        older_link = doc.at_css("a[href='#{client_coordinated_entry_hud_assessment_path(window_destination_client, older_pathways_assessment)}']")

        expect(newer_link).to be_present
        expect(older_link).to be_present
        expect(newer_link.ancestors('tr').first[:style]).to be_nil
        expect(older_link.ancestors('tr').first[:style]).to match(/display:\s*none/)
        expect(doc.css('.jAssessmentTypeToggle')).to be_present
      end

      it 'does not show a link when config is default, even with limited dashboard permission' do
        config.update(client_dashboard: :default)
        setup_access_control(user, limited_dashboard_role, Collection.system_collection(:window_data_sources))
        sign_in user

        get rollup_client_path(window_destination_client, partial: :boston_assessments_with_limited_data)

        expect(response.body).not_to include(client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment))
      end

      it 'does not show a link when config is boston but the user has full (not limited) dashboard permission' do
        config.update(client_dashboard: :boston)
        setup_access_control(user, full_dashboard_role, Collection.system_collection(:window_data_sources))
        sign_in user

        get rollup_client_path(window_destination_client, partial: :boston_assessments_with_limited_data)

        expect(response.body).not_to include(client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment))
      end
    end
  end
end
