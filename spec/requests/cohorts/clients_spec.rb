###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe Cohorts::ClientsController, type: :request do
  include_context 'visibility test context'
  let(:user) { create(:acl_user) }
  let(:other_user) { create(:acl_user) }
  let!(:cohort) { create(:cohort) }
  let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let!(:cohort_role) { create :role, can_view_clients: true, can_edit_clients: true, can_view_cohorts: true, can_add_cohort_clients: true }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, cohort_role, all_cohorts_collection)
    setup_access_control(other_user, cohort_role, all_cohorts_collection)
  end

  describe 'POST /cohorts/:cohort_id/client_searches' do
    let(:search_params) { { q: 'CohortClient' } }

    context 'when logged out' do
      it 'redirects to the login page' do
        post cohort_client_search_queries_path(cohort_id: cohort.id), params: search_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in with insufficient permissions' do
      let(:unauthorized_user) { create(:acl_user) }
      before { sign_in unauthorized_user }

      it 'redirects with an authorization error' do
        post cohort_client_search_queries_path(cohort_id: cohort.id), params: search_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Sorry you are not authorized to do that')
      end
    end

    context 'when logged in with sufficient permissions' do
      before { sign_in user }

      it 'creates a new client search query and redirects' do
        expect do
          post cohort_client_search_queries_path(cohort_id: cohort.id), params: search_params
        end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.created_by).to eq(user)
        expect(query.params['q']).to eq('CohortClient')
        expect(response).to redirect_to(cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: query.id))
      end

      it 'reuses an existing search query for the same parameters' do
        existing_query = create(:grda_warehouse_client_search_query, created_by: user, params: search_params)
        _other_query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'something else' })
        expect do
          post cohort_client_search_queries_path(cohort_id: cohort.id), params: search_params
        end.not_to change(GrdaWarehouse::ClientSearchQuery, :count)

        expect(response).to redirect_to(cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: existing_query.id))
      end
    end
  end

  describe 'GET /cohorts/:cohort_id/client_searches/:id' do
    let!(:client_to_find) { create(:hud_client, FirstName: 'CohortClient') }
    let!(:search_query) { create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'CohortClient' }) }

    context 'when logged out' do
      it 'redirects to the login page' do
        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in with insufficient permissions' do
      let(:unauthorized_user) { create(:acl_user) }
      before { sign_in unauthorized_user }

      it 'redirects with an authorization error' do
        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Sorry you are not authorized to do that')
      end
    end

    context 'when logged in with sufficient permissions' do
      before { sign_in user }

      it 'renders the search results' do
        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('CohortClient')
      end

      it 'touches the updated_at timestamp of the search query' do
        original_updated_at = search_query.updated_at
        travel 1.hour do
          get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
          expect(search_query.reload.updated_at).to be > original_updated_at
        end
      end

      it 'can view a search link created by another authorized user' do
        sign_in other_user
        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('CohortClient')
      end

      it 'handles non-existent search queries gracefully' do
        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: 'non-existent-uuid')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
