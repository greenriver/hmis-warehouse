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
        hmis_ds = create(:hmis_primary_data_source, visible_in_window: true)
        hmis_user = create(:hmis_user, data_source: hmis_ds)
        hmis_ds_viewable_collection = create(:collection)
        hmis_ds_viewable_collection.add_viewable(hmis_ds)
        setup_access_control(user, cohort_role, hmis_ds_viewable_collection)
        # source_data_source_ids/destination_data_source_ids are cached for an hour (see
        # GrdaWarehouse::DataSource); invalidate so the newly-created HMIS data source is
        # picked up by full-text search.
        Rails.cache.delete(:source_data_source_ids)
        Rails.cache.delete(:destination_data_source_ids)

        restricted_source_client = create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzrestrictcohort', last_name: 'Zzclientsensitive')
        restricted_destination_client = create(:grda_warehouse_hud_client, FirstName: 'Zzrestrictcohort', LastName: 'Zzclientsensitive')
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        # Unrestricted sibling matching the same search term, so the assertions below can't
        # pass merely because the search returned nothing at all.
        open_source_client = create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzrestrictcohort', last_name: 'Zzclientopen')
        open_destination_client = create(:grda_warehouse_hud_client, FirstName: 'Zzrestrictcohort', LastName: 'Zzclientopen')
        GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
        restricted_query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'Zzrestrictcohort' })

        get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: restricted_query.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Zzclientopen')
        # The restricted client must be excluded from the result set entirely, not merely
        # redacted in place — a generic "Name Redacted" row would also satisfy the older,
        # weaker assertion that just checked for the absence of the real last name.
        expect(response.body).not_to include('Name Redacted')
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

  describe 'GET /cohorts/:cohort_id/cohort_clients/new (touchpoint search)' do
    let(:searcher) { create(:acl_user) }
    let!(:window_assessment) do
      GrdaWarehouse::Hmis::Assessment.create!(
        data_source_id: window_visible_data_source.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        site_name: 'Main',
        confidential: false,
        active: true,
      )
    end
    let!(:non_window_assessment) do
      GrdaWarehouse::Hmis::Assessment.create!(
        data_source_id: non_window_visible_data_source.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        site_name: 'Main',
        confidential: false,
        active: true,
      )
    end

    before do
      # only_window would hide non-window clients regardless of the user's visibility
      cohort.update!(only_window: false)
      non_window_destination_client.update!(FirstName: 'Seen', LastName: 'Searchable')
      window_destination_client.update!(FirstName: 'Unseen', LastName: 'Elsewhere')
      sources = [
        [window_source_client, window_visible_data_source],
        [non_window_source_client, non_window_visible_data_source],
      ]
      sources.each do |source, data_source|
        GrdaWarehouse::HmisForm.create!(
          client_id: source.id,
          data_source_id: data_source.id,
          site_id: 1,
          assessment_id: 1,
          name: 'Intake',
          collected_at: Date.current,
          staff: 'Staff',
          answers: { sections: [] },
        )
      end
      setup_access_control(searcher, cohort_role, all_cohorts_collection)
      setup_access_control(searcher, can_view_clients, non_window_data_source_viewable_collection)
      sign_in searcher
    end

    it 'lists only clients the user can see' do
      touchpoint_params = { start: 1.week.ago.to_date, end: Date.tomorrow, assessment_id: 1 }

      get new_cohort_cohort_client_path(cohort), params: { touchpoints: touchpoint_params }

      expect(response.body).to include('Searchable')
      expect(response.body).not_to include('Elsewhere')
    end
  end

  describe 'GET /cohorts/:cohort_id/cohort_clients/new (chronic searches)' do
    let(:searcher) { create(:acl_user) }

    before do
      # only_window would hide non-window clients regardless of the user's visibility
      cohort.update!(only_window: false)
      non_window_destination_client.update!(FirstName: 'Seen', LastName: 'Searchable')
      window_destination_client.update!(FirstName: 'Unseen', LastName: 'Elsewhere')
      service_history_enrollments = {
        window_destination_client => window_service_history_enrollment,
        non_window_destination_client => non_window_service_history_enrollment,
      }
      service_history_enrollments.each do |client, enrollment|
        create(:chronic, client: client, date: Date.current, age: 30)
        create(:hud_chronic, client: client, date: Date.current, age: 30)
        create(
          :service_history_service,
          client_id: client.id,
          service_history_enrollment_id: enrollment.id,
          record_type: 'service',
          date: Date.current,
          project_type: 1,
          homeless: true,
          literally_homeless: true,
        )
      end
      setup_access_control(searcher, cohort_role, all_cohorts_collection)
      setup_access_control(searcher, can_view_clients, non_window_data_source_viewable_collection)
      sign_in searcher
    end

    it 'lists only clients the user can see from the chronic panel' do
      get new_cohort_cohort_client_path(cohort), params: { filter: { hoh: '0' } }

      expect(response.body).to include('Searchable')
      expect(response.body).not_to include('Elsewhere')
    end

    it 'lists only clients the user can see from the HUD chronic panel' do
      get new_cohort_cohort_client_path(cohort), params: { hud_filter: { hoh: '0' } }

      expect(response.body).to include('Searchable')
      expect(response.body).not_to include('Elsewhere')
    end
  end

  describe 'POST /cohorts/:cohort_id/cohort_clients (create)' do
    let!(:client1) { non_window_destination_client }
    let!(:client2) { both_destination_client }

    # only_window would hide non-window clients regardless of the user's visibility
    before { cohort.update!(only_window: false) }
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

    context 'with a client outside the user\'s visibility' do
      let(:adder) { create(:acl_user) }

      before do
        setup_access_control(adder, cohort_role, all_cohorts_collection)
        setup_access_control(adder, can_view_clients, non_window_data_source_viewable_collection)
        sign_in adder
      end

      it 'adds only the visible client' do
        params = { grda_warehouse_cohort: { client_ids: "#{non_window_destination_client.id},#{window_destination_client.id}" } }

        expect do
          post cohort_cohort_clients_path(cohort), params: params
        end.to have_enqueued_job(AddCohortClientsJob).with(cohort.id, non_window_destination_client.id.to_s, adder.id)

        expect(cohort.cohort_clients.pluck(:client_id)).to contain_exactly(non_window_destination_client.id)
        expect(flash[:notice]).to include('1 Client added')
      end

      it 'adds nothing when no requested client is visible' do
        params = { grda_warehouse_cohort: { client_ids: window_destination_client.id.to_s } }

        expect do
          post cohort_cohort_clients_path(cohort), params: params
        end.not_to have_enqueued_job(AddCohortClientsJob)

        expect(cohort.cohort_clients.count).to eq(0)
        expect(flash[:error]).to include('No clients were added')
      end
    end

    context 'when logged in with sufficient permissions' do
      before do
        setup_access_control(user, can_view_clients, non_window_data_source_viewable_collection)
        sign_in user
      end

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

    it 'resolves retention marks for the page in one query, not once per client' do
      3.times { cohort.cohort_clients.create!(client_id: create(:hud_client, FirstName: 'CohortClient').id) }

      expect do
        get cohort_cohort_clients_path(cohort, format: :json), params: { content: true, page: 1, per: 50 }
      end.to make_database_queries(matching: /FROM "client_retention_marks"/, count: 1)
    end

    it 'wires current_user onto every visible column' do
      # GrdaWarehouse::Cohort#visible_columns sets current_user on each column; without
      # that, CohortColumns::Base#client_restricted? raises on a nil current_user.
      get cohort_cohort_clients_path(cohort, format: :json), params: { content: true, page: 1, per: 50 }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /cohorts/:cohort_id/cohort_clients/new with a HUD chronic search' do
    before { sign_in user }

    it 'builds the HUD chronic filter from the submitted hud_filter params' do
      get new_cohort_cohort_client_path(cohort), params: { hud_filter: { on: '2026-01-01', min_age: '24' } }

      expect(response).to have_http_status(:ok)
      selected = Nokogiri::HTML(response.body).at_css('#hud_filter_min_age option[selected]')
      expect(selected&.[]('value')).to eq('24')
    end
  end

  describe 'GET /cohorts/:cohort_id/cohort_clients (html)' do
    before do
      sign_in user
      GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create!(**rule) }
      create_list(:hud_client, 4).each { |client| cohort.cohort_clients.create!(client_id: client.id) }
    end

    it 'renders every row with the client restrictions preloaded' do
      get cohort_cohort_clients_path(cohort_id: cohort.id), params: { page: 1, per: 50 }

      expect(response).to have_http_status(:ok)
      expect(response.body.scan('jCohortClient').size).to eq(4)
    end
  end

  describe 'bulk removing and restoring clients' do
    let!(:other_cohort) { create(:cohort) }
    let!(:own_cohort_client) { cohort.cohort_clients.create!(client_id: create(:hud_client).id) }
    let!(:other_cohort_client) { other_cohort.cohort_clients.create!(client_id: create(:hud_client).id) }
    let(:cohort_client_ids) { [own_cohort_client.id, other_cohort_client.id].join(',') }

    before { sign_in user }

    describe 'DELETE /cohorts/:cohort_id/cohort_clients/bulk_destroy' do
      it 'removes only cohort clients that belong to the URL cohort' do
        delete bulk_destroy_cohort_cohort_clients_path(cohort), params: { cc: { cohort_client_ids: cohort_client_ids } }

        expect(own_cohort_client.reload.deleted?).to be(true)
        expect(other_cohort_client.reload.deleted?).to be(false)
        expect(flash[:notice]).to eq('Removed 1 client')
      end
    end

    describe 'POST /cohorts/:cohort_id/cohort_clients/bulk_restore' do
      before do
        own_cohort_client.destroy!
        other_cohort_client.destroy!
      end

      it 'restores only cohort clients that belong to the URL cohort' do
        post bulk_restore_cohort_cohort_clients_path(cohort), params: { cc: { cohort_client_ids: cohort_client_ids } }

        expect(own_cohort_client.reload.deleted?).to be(false)
        expect(other_cohort_client.reload.deleted?).to be(true)
      end
    end
  end
end
