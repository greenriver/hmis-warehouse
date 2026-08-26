###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ClientMatchesController', type: :request do
  let!(:user) { create(:acl_user) }
  # `ClientMatchesController` gates on `before_action :require_can_edit_clients!` — `:admin_role`
  # (see Task 8's note) grants no permissions by itself, so set this explicitly.
  let!(:role) { create(:role, can_edit_clients: true) }
  # `Collection.system_collections` has no `:client_matches` entry — `can_edit_clients?` is
  # granted through any AccessControl regardless of which collection it's attached to (see
  # `User#load_effective_permissions`, which iterates `roles` unfiltered by collection), so reuse
  # `:data_sources` here the same way `spec/requests/clients/notes_controller_spec.rb` does.
  let!(:collection) { Collection.system_collection(:data_sources) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  # No FactoryBot factory exists for GrdaWarehouse::ClientMatch (confirmed via repo-wide grep) —
  # build directly. `ClientMatch belongs_to :source_client` / `:destination_client` (both
  # `class_name: 'GrdaWarehouse::Hud::Client'` — NOT `candidate_client`), and `status` must be one
  # of `['candidate', 'accepted', 'rejected', 'processed_sources']`. The controller's default filter
  # (`ClientMatchesController#index`) is `status: 'candidate'`.
  #
  # `index`'s query does `.joins(source_client: :destination_client, destination_client: :destination_client)`
  # — an INNER JOIN — so BOTH `ClientMatch#source_client` and `ClientMatch#destination_client` must
  # themselves be SOURCE-side `GrdaWarehouse::Hud::Client` rows with their own resolvable
  # `destination_client` (via `WarehouseClient`), not bare destination rows. The view's
  # `dest.destination_client.id if dest.source?` branch confirms this shape. Reuse
  # `restricted_source_client` (already source-mapped to `restricted_destination_client` in the
  # standard fixture block below) as `ClientMatch#destination_client`, and build a second,
  # independent source/destination pair for `ClientMatch#source_client`.
  let!(:candidate_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Candidate', LastName: 'Client') }
  let!(:candidate_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Candidate', last_name: 'Client') }
  let!(:match) do
    GrdaWarehouse::ClientMatch.create!(
      destination_client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id),
      source_client: GrdaWarehouse::Hud::Client.find(candidate_source_client.id),
      status: 'candidate',
      # `_client_match.haml` renders `match.score.round(2).abs` unconditionally.
      score: -1.0,
    )
  end

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination_client.id, source_id: candidate_source_client.id, data_source_id: hmis_ds.id, id_in_source: candidate_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the restricted destination client name in the match heading' do
    get client_matches_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end
end
