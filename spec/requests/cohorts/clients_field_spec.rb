###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohorts::ClientsController#field', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let!(:cohort_role) { create(:role, can_view_clients: true, can_view_cohorts: true, can_add_cohort_clients: true, can_manage_cohort_data: true) }
  let!(:cohort) { create(:cohort) }
  let!(:client) { create(:grda_warehouse_hud_client) }
  let!(:cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: client) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, cohort_role, all_cohorts_collection)
    sign_in user
  end

  it 'renders a read-only column without raising' do
    get field_cohort_cohort_client_path(cohort, cohort_client), params: { field: 'CohortColumns::ClientId' }

    expect(response).to have_http_status(:ok)
  end

  it 'renders an editable column without raising' do
    get field_cohort_cohort_client_path(cohort, cohort_client), params: { field: 'CohortColumns::Rank' }

    expect(response).to have_http_status(:ok)
  end
end
