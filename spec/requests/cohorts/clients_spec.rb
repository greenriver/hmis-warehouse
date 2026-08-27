###
# Copyright Green River Data Group, Inc.
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
        expect_unauthenticated_warehouse_request do
          post cohort_client_search_queries_path(cohort_id: cohort.id), params: search_params
        end
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
        expect_unauthenticated_warehouse_request do
          get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)
        end
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

      it 'does not show a restricted client matched by name' do
        hmis_ds = create(:hmis_primary_data_source)
        hmis_user = create(:hmis_user, data_source: hmis_ds)
        restricted_source_client = create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzrestrictcohort', last_name: 'Zzclientsensitive')
        restricted_destination_client = create(:grda_warehouse_hud_client, FirstName: 'Zzrestrictcohort', LastName: 'Zzclientsensitive')
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        restricted_query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'Zzrestrictcohort' })

        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: restricted_query.id)

        expect(response).to have_http_status(:ok)
        # 'Zzrestrictcohort' itself is echoed back into the search box's value= attribute
        # regardless of results, so assert on the last name instead — it only appears if a
        # client row actually rendered.
        expect(response.body).not_to include('Zzclientsensitive')
      end

      context 'when a matching client has been marked restricted in HMIS' do
        let!(:hmis_ds) { create(:hmis_primary_data_source, visible_in_window: true) }
        let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
        let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'CohortClient', last_name: 'Sensitive') }
        let!(:restricted_destination_client) { create(:hud_client, FirstName: 'CohortClient', LastName: 'Sensitive', SSN: '111223333') }
        let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'CohortClient', last_name: 'Open') }
        let!(:open_destination_client) { create(:hud_client, FirstName: 'CohortClient', LastName: 'Open', SSN: '444556666') }

        let!(:hmis_ds_viewable_collection) { create(:collection) }

        before do
          # source_data_source_ids/destination_data_source_ids are cached for an hour (see
          # GrdaWarehouse::DataSource); invalidate so the newly-created HMIS data source is
          # picked up by full-text search.
          Rails.cache.delete(:source_data_source_ids)
          Rails.cache.delete(:destination_data_source_ids)
          GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
          GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
          restricted_source_client.mark_as_restricted!(user: hmis_user)

          # hmis_ds is authoritative, so granting can_view_clients directly on it (rather
          # than on a project/enrollment) is enough to make its clients search-visible.
          hmis_ds_viewable_collection.add_viewable(hmis_ds)
          setup_access_control(user, cohort_role, hmis_ds_viewable_collection)
        end

        it 'excludes the restricted client entirely from a name search, while leaving the unrestricted client intact' do
          get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include('Name Redacted')
          expect(response.body).not_to include('Sensitive')
          expect(response.body).not_to include('111223333')

          expect(response.body).to include('Open')
          expect(response.body).to include('XXX-XX-6666')
          expect(response.body).not_to include('444556666')
        end
      end
    end
  end

  describe 'POST /cohorts/:cohort_id/cohort_clients (create)' do
    let!(:client1) { create(:grda_warehouse_hud_client, data_source_id: warehouse_data_source.id) }
    let!(:client2) { create(:grda_warehouse_hud_client, data_source_id: warehouse_data_source.id) }
    let(:create_params) { { grda_warehouse_cohort: { client_ids: "#{client1.id},#{client2.id}" } } }

    context 'when logged out' do
      it 'redirects to the login page' do
        expect_unauthenticated_warehouse_request do
          post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        end
      end
    end

    context 'when logged in with insufficient permissions' do
      let(:unauthorized_user) { create(:acl_user) }
      before { sign_in unauthorized_user }

      it 'redirects with an authorization error' do
        post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Sorry you are not authorized to do that')
      end
    end

    context 'when logged in with sufficient permissions' do
      before { sign_in user }

      it 'adds clients to the cohort' do
        expect do
          post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        end.to change { cohort.cohort_clients.count }.by(2)

        expect(cohort.cohort_clients.pluck(:client_id)).to contain_exactly(client1.id, client2.id)
        expect(response).to redirect_to(cohort_path(cohort))
        expect(flash[:notice]).to include('2 Clients added')
      end

      it 'enqueues AddCohortClientsJob to populate client data' do
        expect do
          post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        end.to have_enqueued_job(AddCohortClientsJob).with(cohort.id, "#{client1.id},#{client2.id}", user.id)
      end

      it 'skips clients already in the cohort' do
        cohort.cohort_clients.create!(client_id: client1.id)
        expect do
          post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        end.to change { cohort.cohort_clients.count }.by(1)

        expect(cohort.cohort_clients.pluck(:client_id)).to contain_exactly(client1.id, client2.id)
      end

      it 'restores previously deleted clients when their IDs are included' do
        cohort_client = cohort.cohort_clients.create!(client_id: client1.id)
        cohort_client.destroy!
        expect(cohort.cohort_clients.with_deleted.count).to eq(1)

        expect do
          post cohort_cohort_clients_path(cohort_id: cohort.id), params: create_params
        end.to change { cohort.cohort_clients.count }.from(0).to(2)

        expect(cohort_client.reload.deleted?).to be false
      end
    end
  end

  describe 'GET /cohorts/:cohort_id/cohort_clients (index, content=true)' do
    # This is the JSON grid the ag-Grid UI actually renders (app/javascript/cohorts.ts),
    # via Cohorts::ClientsController#data_for_table -> CohortColumns::Base#pii_provider.
    # The search-results path above exercises a different controller action entirely.
    let!(:hmis_ds) { create(:hmis_primary_data_source, visible_in_window: true) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'CohortClient', last_name: 'Sensitive') }
    let!(:restricted_destination_client) { create(:hud_client, FirstName: 'CohortClient', LastName: 'Sensitive', SSN: '111223333') }
    let!(:open_destination_client) { create(:hud_client, FirstName: 'CohortClient', LastName: 'Open', SSN: '444556666') }

    before do
      # The :cohort factory doesn't create cohort_tabs (unlike CohortsController#create in
      # the real app), and #search_clients requires one to select a population.
      GrdaWarehouse::CohortTab.default_rules.each do |rule|
        cohort.cohort_tabs.create!(**rule)
      end

      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)

      cohort.cohort_clients.create!(client_id: restricted_destination_client.id)
      cohort.cohort_clients.create!(client_id: open_destination_client.id)
      cohort.update!(column_state: [
                       CohortColumns::FirstName.new,
                       CohortColumns::LastName.new,
                       CohortColumns::Dob.new,
                       CohortColumns::Ssn.new,
                     ])
      sign_in user
    end

    it "redacts the restricted client's PII cells and leaves the unrestricted client's intact" do
      get cohort_cohort_clients_path(cohort, format: :json), params: { content: true, page: 1, per: 50 }

      expect(response).to have_http_status(:ok)
      rows = JSON.parse(response.body)

      restricted_client_id = cohort.cohort_clients.find_by(client_id: restricted_destination_client.id).id
      open_client_id = cohort.cohort_clients.find_by(client_id: open_destination_client.id).id
      restricted_row = rows.find { |row| row['first_name']['cohort_client_id'] == restricted_client_id }
      open_row = rows.find { |row| row['first_name']['cohort_client_id'] == open_client_id }

      expect(restricted_row['first_name']['value']).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(restricted_row['last_name']['value']).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(restricted_row['ssnumber']['value']).to include(GrdaWarehouse::PiiProvider::REDACTED)
      expect(response.body).not_to include('Sensitive')
      expect(response.body).not_to include('111223333')

      expect(open_row['first_name']['value']).to include('CohortClient')
      expect(open_row['last_name']['value']).to include('Open')
      expect(open_row['ssnumber']['value']).to include('XXX-XX-6666')
    end

    it 'wires current_user onto every visible column' do
      # GrdaWarehouse::Cohort#visible_columns sets current_user on each column; without
      # that, CohortColumns::Base#client_restricted? raises on a nil current_user.
      get cohort_cohort_clients_path(cohort, format: :json), params: { content: true, page: 1, per: 50 }

      expect(response).to have_http_status(:ok)
    end
  end
end
