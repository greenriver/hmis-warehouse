# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'admin users search', shared_context: :metadata do
  describe 'POST /admin/users/searches' do
    let(:search_params) { { q: 'Alice' } }

    context 'when logged out' do
      it 'redirects to the login page' do
        post admin_user_search_queries_path, params: search_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in as a non-admin user' do
      before { sign_in user }

      it 'redirects with an authorization error' do
        post admin_user_search_queries_path, params: search_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Sorry you are not authorized to do that')
      end
    end

    context 'when logged in as an admin user' do
      before { sign_in admin_user }

      it 'creates a new client search query and redirects' do
        expect do
          post admin_user_search_queries_path, params: search_params
        end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)

        query = GrdaWarehouse::ClientSearchQuery.last
        expect(query.created_by).to eq(admin_user)
        expect(query.params['q']).to eq('Alice')
        expect(response).to redirect_to(user_search_query_admin_users_path(id: query.id))
      end

      it 'reuses an existing search query for the same parameters' do
        existing_query = create(:grda_warehouse_client_search_query, created_by: admin_user, params: search_params)
        _other_query = create(:grda_warehouse_client_search_query, created_by: admin_user, params: { q: 'something else' })
        expect do
          post admin_user_search_queries_path, params: search_params
        end.not_to change(GrdaWarehouse::ClientSearchQuery, :count)

        expect(response).to redirect_to(user_search_query_admin_users_path(id: existing_query.id))
      end
    end
  end

  describe 'GET /admin/users/searches/:id' do
    let!(:search_query) { create(:grda_warehouse_client_search_query, created_by: admin_user, params: { q: 'Alice' }) }

    context 'when logged out' do
      it 'redirects to the login page' do
        get user_search_query_admin_users_path(id: search_query.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in as a non-admin user' do
      before { sign_in user }

      it 'redirects with an authorization error' do
        get user_search_query_admin_users_path(id: search_query.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Sorry you are not authorized to do that')
      end
    end

    context 'when logged in as an admin user' do
      before { sign_in admin_user }

      it 'renders the search results' do
        get user_search_query_admin_users_path(id: search_query.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Alice')
      end

      it 'touches the updated_at timestamp of the search query' do
        original_updated_at = search_query.updated_at
        travel 1.hour do
          get user_search_query_admin_users_path(id: search_query.id)
          expect(search_query.reload.updated_at).to be > original_updated_at
        end
      end

      it 'can view a search link created by another admin' do
        search_query_from_other_admin = create(:grda_warehouse_client_search_query, created_by: other_admin, params: { q: 'Samwise' })
        get user_search_query_admin_users_path(id: search_query_from_other_admin.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Samwise')
      end

      it 'handles non-existent search queries gracefully' do
        get user_search_query_admin_users_path(id: 'non-existent-uuid')
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:error]).to eq('Search query not found')
      end
    end
  end
end
