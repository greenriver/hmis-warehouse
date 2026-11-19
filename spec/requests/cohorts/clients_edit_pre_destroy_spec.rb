###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohorts::ClientsController edit/pre_destroy', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let!(:cohort_role) { create(:role, can_view_clients: true, can_view_cohorts: true, can_add_cohort_clients: true, can_manage_cohort_data: true) }
  let!(:cohort) { create(:cohort) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: restricted_destination_client) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, cohort_role, all_cohorts_collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name in the edit modal title' do
    get edit_cohort_cohort_client_path(cohort, cohort_client)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  it 'redacts the client name in the pre_destroy confirmation modal' do
    get pre_destroy_cohort_cohort_client_path(cohort, cohort_client)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  context 'when the user can view the cohort but cannot add cohort clients' do
    let!(:viewer) { create(:acl_user) }
    let!(:viewer_role) { create(:role, name: 'cohort viewer', can_view_clients: true, can_view_cohorts: true) }

    before do
      setup_access_control(viewer, viewer_role, all_cohorts_collection)
      sign_in viewer
    end

    it 'does not restore a removed client via pre_destroy' do
      cohort_client.destroy

      get pre_destroy_cohort_cohort_client_path(cohort, cohort_client)

      expect(response).to redirect_to(viewer.my_root_path)
      expect(cohort_client.reload.deleted_at).to be_present
    end

    it 'does not run a saved cohort client search' do
      search_query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'Client' })

      get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)

      expect(response).to redirect_to(viewer.my_root_path)
    end

    it 'does not render the bulk removal confirmation' do
      post pre_bulk_destroy_cohort_cohort_clients_path(cohort_id: cohort.id), params: { cc: { cohort_client_ids: cohort_client.id.to_s } }

      expect(response).to redirect_to(viewer.my_root_path)
    end
  end

  context 'when the user can add cohort clients' do
    it 'runs a saved cohort client search' do
      search_query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: 'Client' })

      get cohort_cohort_client_search_query_path(cohort_id: cohort.id, id: search_query.id)

      expect(response).to have_http_status(:ok)
    end

    it 'renders the bulk removal confirmation' do
      post pre_bulk_destroy_cohort_cohort_clients_path(cohort_id: cohort.id), params: { cc: { cohort_client_ids: cohort_client.id.to_s } }

      expect(response).to have_http_status(:ok)
    end
  end
end
