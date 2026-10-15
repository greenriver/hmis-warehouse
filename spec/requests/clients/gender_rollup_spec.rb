###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe 'Client dashboard gender rollup', type: :request do
  include_context 'visibility test context'

  let!(:user) { create :acl_user }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    sign_in user
  end

  it 'lists every visible source client when more than the preload miss threshold are linked' do
    sources = Array.new(preload_miss_client_count) do |i|
      source = create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id, FirstName: "Gender#{i}", LastName: 'Coverage')
      create(:grda_warehouse_hud_enrollment, data_source_id: window_visible_data_source.id, PersonalID: source.PersonalID, ProjectID: window_project.ProjectID, EntryDate: 1.month.ago.to_date)
      GrdaWarehouse::WarehouseClient.create!(destination_id: window_destination_client.id, source_id: source.id, data_source_id: window_visible_data_source.id, id_in_source: source.PersonalID)
      source
    end

    get rollup_client_path(window_destination_client, partial: :gender), xhr: true

    expect(response).to have_http_status(:ok)
    sources.each { |source| expect(response.body).to include(source.FirstName) }
  end
end
