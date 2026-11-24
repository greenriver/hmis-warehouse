###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohort client, note and search query authorization', type: :request do
  let(:user) { create(:acl_user) }
  let!(:cohort_a) { create(:cohort, name: 'Cohort A') }
  let!(:cohort_b) { create(:cohort, name: 'Cohort B') }
  let!(:client_a) { create(:grda_warehouse_hud_client, FirstName: 'Alpha', LastName: 'Aardvark') }
  let!(:client_b) { create(:grda_warehouse_hud_client, FirstName: 'Beta', LastName: 'Bison') }
  let!(:cohort_client_a) { GrdaWarehouse::CohortClient.create!(cohort: cohort_a, client: client_a) }
  let!(:cohort_client_b) { GrdaWarehouse::CohortClient.create!(cohort: cohort_b, client: client_b) }

  before do
    Collection.maintain_system_groups
    [cohort_a, cohort_b].each do |cohort|
      GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create!(**rule) }
      cohort.update!(column_state: GrdaWarehouse::Cohort.available_columns)
    end
  end

  def role_with(*permissions)
    create(:role, **permissions.index_with { true })
  end

  def grant_acl(user, permissions, *records)
    collection = create(:collection)
    collection.set_viewables({ cohorts: records.map(&:id) })
    setup_access_control(user, role_with(*permissions), collection)
  end

  def grant_legacy(user, permissions, *records)
    access_group = create(:access_group)
    role_with(*permissions).add(user)
    access_group.add(user)
    records.each { |record| access_group.add_viewable(record) }
  end

  def refused?
    response.redirect? && !response.location.include?('/cohorts/')
  end

  def row_ids(cohort, population:)
    get cohort_cohort_clients_path(cohort, format: :json), params: { content: true, population: population, page: 1, per: 50 }
    expect(response).to have_http_status(:ok)
    JSON.parse(response.body).map { |row| row['meta']['cohort_client_id'] }
  end

  shared_examples 'per-cohort client authorization' do
    before { sign_in user }

    it 'refuses a manager-only user on every read action and shows no client data' do
      grant(user, [:can_configure_cohorts], cohort_a)
      cohort_client_a.destroy

      [
        cohort_cohort_clients_path(cohort_a, format: :json),
        cohort_cohort_client_path(cohort_a, cohort_client_a, format: :json),
        field_cohort_cohort_client_path(cohort_a, cohort_client_a, field: 'CohortColumns::Rank'),
        cohort_cohort_client_cohort_client_notes_path(cohort_a, cohort_client_a),
        cohort_cohort_client_client_notes_path(cohort_a, cohort_client_a),
      ].each do |path|
        get path

        expect(refused?).to be(true), "expected #{path} to be refused"
        expect(response.body).not_to include(client_a.FirstName)
      end
    end

    it 'refuses a viewer of another cohort on every read action and shows no client data' do
      grant(user, [:can_view_cohorts, :can_view_clients], cohort_a)

      [
        cohort_cohort_clients_path(cohort_b, format: :json),
        cohort_cohort_clients_path(cohort_b, format: :json, content: true, page: 1, per: 50),
        cohort_cohort_client_path(cohort_b, cohort_client_b, format: :json),
        field_cohort_cohort_client_path(cohort_b, cohort_client_b, field: 'CohortColumns::Rank'),
        cohort_cohort_client_cohort_client_notes_path(cohort_b, cohort_client_b),
        cohort_cohort_client_client_notes_path(cohort_b, cohort_client_b),
      ].each do |path|
        get path

        expect(refused?).to be(true), "expected #{path} to be refused"
        expect(response.body).not_to include(client_b.FirstName)
        expect(response.body).not_to include(client_b.LastName)
      end
    end

    it 'refuses a manager-only user the search query create' do
      grant(user, [:can_configure_cohorts], cohort_a)

      expect do
        post cohort_client_search_queries_path(cohort_a), params: { q: 'Alpha' }
      end.not_to change(GrdaWarehouse::ClientSearchQuery, :count)
      expect(refused?).to be(true)
    end

    it 'refuses every write on a cohort the user has no access to, and allows it where access was granted' do
      full = [:can_view_cohorts, :can_participate_in_cohorts, :can_add_cohort_clients, :can_view_clients]
      grant(user, full, cohort_a)
      extra_client = create(:grda_warehouse_hud_client)

      post cohort_client_search_queries_path(cohort_b), params: { q: 'Alpha' }
      expect(refused?).to be(true)
      get new_cohort_cohort_client_path(cohort_b)
      expect(refused?).to be(true)
      expect do
        post cohort_cohort_clients_path(cohort_b), params: { grda_warehouse_cohort: { client_ids: extra_client.id.to_s } }
      end.not_to change(cohort_b.cohort_clients, :count)
      delete cohort_cohort_client_path(cohort_b, cohort_client_b)
      expect(GrdaWarehouse::CohortClient.exists?(cohort_client_b.id)).to be(true)
      patch cohort_cohort_client_path(cohort_b, cohort_client_b, format: :json), params: { cohort_client: { rank: 7 } }
      expect(cohort_client_b.reload.rank).not_to eq(7)
      expect do
        post cohort_cohort_client_cohort_client_notes_path(cohort_b, cohort_client_b),
             params: { grda_warehouse_cohort_client_note: { note: 'Denied note' } }
      end.not_to change(GrdaWarehouse::CohortClientNote, :count)

      expect do
        post cohort_client_search_queries_path(cohort_a), params: { q: 'Alpha' }
      end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)
      get new_cohort_cohort_client_path(cohort_a)
      expect(response).to have_http_status(:ok)
      patch cohort_cohort_client_path(cohort_a, cohort_client_a, format: :json), params: { cohort_client: { rank: 7 } }
      expect(cohort_client_a.reload.rank).to eq(7)
      expect do
        post cohort_cohort_client_cohort_client_notes_path(cohort_a, cohort_client_a),
             params: { grda_warehouse_cohort_client_note: { note: 'Allowed note' } }
      end.to change(GrdaWarehouse::CohortClientNote, :count).by(1)
      delete cohort_cohort_client_path(cohort_a, cohort_client_a)
      expect(GrdaWarehouse::CohortClient.exists?(cohort_client_a.id)).to be(false)
    end

    it 'does not resolve a cohort client from another cohort through the cohort client notes path' do
      grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_a)

      get cohort_cohort_client_cohort_client_notes_path(cohort_a, cohort_client_b)

      expect(response).to have_http_status(:not_found)
    end

    it 'does not resolve a cohort client from another cohort through the client notes path' do
      grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_a)

      get cohort_cohort_client_client_notes_path(cohort_a, cohort_client_b)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a cohort that does not exist' do
      grant(user, [:can_view_cohorts], cohort_a)

      get cohort_cohort_clients_path(GrdaWarehouse::Cohort.maximum(:id) + 1, format: :json)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with an ACL user' do
    def grant(...) = grant_acl(...)

    include_examples 'per-cohort client authorization'

    describe 'permissions that differ between cohorts' do
      before { sign_in user }

      it 'allows the search query create for add-clients on this cohort only' do
        grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        expect do
          post cohort_client_search_queries_path(cohort_b), params: { q: 'Alpha' }
        end.not_to change(GrdaWarehouse::ClientSearchQuery, :count)
        expect(refused?).to be(true)

        expect do
          post cohort_client_search_queries_path(cohort_a), params: { q: 'Alpha' }
        end.to change(GrdaWarehouse::ClientSearchQuery, :count).by(1)
      end

      it 'limits new, create and destroy to cohorts where add-clients was granted' do
        grant(user, [:can_view_cohorts, :can_add_cohort_clients, :can_view_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)
        extra_client = create(:grda_warehouse_hud_client)

        get new_cohort_cohort_client_path(cohort_b)
        expect(refused?).to be(true)

        expect do
          post cohort_cohort_clients_path(cohort_b), params: { grda_warehouse_cohort: { client_ids: extra_client.id.to_s } }
        end.not_to change(cohort_b.cohort_clients, :count)
        expect(refused?).to be(true)

        delete cohort_cohort_client_path(cohort_b, cohort_client_b)
        expect(refused?).to be(true)
        expect(GrdaWarehouse::CohortClient.exists?(cohort_client_b.id)).to be(true)

        get new_cohort_cohort_client_path(cohort_a)
        expect(response).to have_http_status(:ok)

        delete cohort_cohort_client_path(cohort_a, cohort_client_a)
        expect(GrdaWarehouse::CohortClient.exists?(cohort_client_a.id)).to be(false)
      end

      it 'limits update to cohorts where participate was granted' do
        grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        patch cohort_cohort_client_path(cohort_b, cohort_client_b, format: :json), params: { cohort_client: { rank: 7 } }
        expect(refused?).to be(true)
        expect(cohort_client_b.reload.rank).not_to eq(7)

        patch cohort_cohort_client_path(cohort_a, cohort_client_a, format: :json), params: { cohort_client: { rank: 7 } }
        expect(response).to have_http_status(:ok)
        expect(cohort_client_a.reload.rank).to eq(7)
      end

      it 'does not offer the remove link on a cohort where add-clients was not granted' do
        grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)
        grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_b)
        cohort_b.update!(column_state: [CohortColumns::FirstName.new, CohortColumns::Rank.new])

        get edit_cohort_cohort_client_path(cohort_b, cohort_client_b)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(pre_destroy_cohort_cohort_client_path(cohort_b, cohort_client_b))
      end

      it 'adds the delete column to the grid only where add-clients was granted' do
        grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        get cohort_cohort_clients_path(cohort_a, format: :json), params: { content: true, page: 1, per: 50 }
        expect(JSON.parse(response.body).first.keys).to include('delete')

        get cohort_cohort_clients_path(cohort_b, format: :json), params: { content: true, page: 1, per: 50 }
        expect(JSON.parse(response.body).first.keys).not_to include('delete')
      end

      it 'shows a removed client only on cohorts where view-deleted was granted' do
        cohort_client_a.destroy
        cohort_client_b.destroy
        grant(user, [:can_view_cohorts, :can_view_deleted_cohort_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        expect(row_ids(cohort_a, population: 'Removed Clients')).to contain_exactly(cohort_client_a.id)
        expect(row_ids(cohort_b, population: 'Removed Clients')).to be_empty
      end

      it 'returns a removed row from show only where view-deleted was granted' do
        cohort_client_a.destroy
        cohort_client_b.destroy
        grant(user, [:can_view_cohorts, :can_view_deleted_cohort_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        get cohort_cohort_client_path(cohort_a, cohort_client_a, format: :json)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(cohort_client_a.id)

        get cohort_cohort_client_path(cohort_b, cohort_client_b, format: :json)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a live row from show for a viewer' do
        grant(user, [:can_view_cohorts], cohort_b)

        get cohort_cohort_client_path(cohort_b, cohort_client_b, format: :json)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to eq(cohort_client_b.id)
      end

      it 'refuses search, pre_destroy, pre_bulk_destroy, bulk_destroy, bulk_restore and re_rank on a cohort without the matching grant' do
        grant(user, [:can_view_cohorts, :can_participate_in_cohorts, :can_add_cohort_clients, :can_view_clients], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)
        second_b = GrdaWarehouse::CohortClient.create!(cohort: cohort_b, client: create(:grda_warehouse_hud_client))
        removed_b = GrdaWarehouse::CohortClient.create!(cohort: cohort_b, client: create(:grda_warehouse_hud_client), rank: 3)
        removed_b.destroy
        query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'Alpha' })
        ids = [cohort_client_b.id, second_b.id]
        original_ranks = ids.map { |id| GrdaWarehouse::CohortClient.find(id).rank }

        get cohort_cohort_client_search_query_path(cohort_id: cohort_b.id, id: query.id)
        expect(refused?).to be(true)

        get pre_destroy_cohort_cohort_client_path(cohort_b, cohort_client_b)
        expect(refused?).to be(true)

        get pre_destroy_cohort_cohort_client_path(cohort_b, removed_b)
        expect(refused?).to be(true)
        expect(GrdaWarehouse::CohortClient.only_deleted.exists?(removed_b.id)).to be(true)

        post pre_bulk_destroy_cohort_cohort_clients_path(cohort_b), params: { cc: { cohort_client_ids: ids.join(',') } }
        expect(refused?).to be(true)

        delete bulk_destroy_cohort_cohort_clients_path(cohort_b), params: { cc: { cohort_client_ids: ids.join(',') } }
        expect(refused?).to be(true)
        expect(cohort_b.cohort_clients.where(id: ids).count).to eq(2)

        post bulk_restore_cohort_cohort_clients_path(cohort_b), params: { cc: { cohort_client_ids: removed_b.id.to_s } }
        expect(refused?).to be(true)
        expect(GrdaWarehouse::CohortClient.only_deleted.exists?(removed_b.id)).to be(true)

        patch re_rank_cohort_cohort_clients_path(cohort_b), params: { rank_order: ids.reverse.join(',') }
        expect(refused?).to be(true)
        expect(ids.map { |id| GrdaWarehouse::CohortClient.find(id).rank }).to eq(original_ranks)
      end

      it 'limits note creation to cohorts where participate was granted' do
        grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_a)
        grant(user, [:can_view_cohorts], cohort_b)

        expect do
          post cohort_cohort_client_cohort_client_notes_path(cohort_b, cohort_client_b),
               params: { grda_warehouse_cohort_client_note: { note: 'Denied note' } }
        end.not_to change(GrdaWarehouse::CohortClientNote, :count)
        expect(refused?).to be(true)

        expect do
          post cohort_cohort_client_cohort_client_notes_path(cohort_a, cohort_client_a),
               params: { grda_warehouse_cohort_client_note: { note: 'Allowed note' } }
        end.to change(GrdaWarehouse::CohortClientNote, :count).by(1)
      end
    end
  end

  context 'with a legacy user' do
    let(:user) { create(:user) }

    def grant(...) = grant_legacy(...)

    include_examples 'per-cohort client authorization'
  end
end
