###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe Cohorts::ClientNotesController, type: :request do
  include_context 'visibility test context'
  let(:user) { create(:acl_user) }
  let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let!(:cohort_role) { create(:role, can_view_clients: true, can_view_cohorts: true, can_add_cohort_clients: true) }
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
    # Set up column_state with default columns including Notes
    cohort.update(column_state: GrdaWarehouse::Cohort.available_columns)
    sign_in user
  end

  it 'redacts the client name in the notes modal title' do
    get cohort_cohort_client_client_notes_path(cohort, cohort_client)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  describe 'changing notes' do
    let(:editor) { create(:acl_user) }
    let!(:own_note) do
      GrdaWarehouse::ClientNotes::CohortNote.create!(client: restricted_destination_client, user: editor, note: 'Own client note')
    end
    let!(:unrelated_note) do
      GrdaWarehouse::ClientNotes::CohortNote.create!(client: create(:grda_warehouse_hud_client), user: user, note: 'Unrelated note')
    end

    before do
      setup_access_control(editor, create(:cohort_client_editor), all_cohorts_collection)
      sign_in editor
    end

    it 'deletes a note on the URL client' do
      delete cohort_cohort_client_client_note_path(cohort, cohort_client, own_note)

      expect(GrdaWarehouse::ClientNotes::CohortNote.exists?(own_note.id)).to be(false)
    end

    it 'does not delete a note that belongs to another client' do
      delete cohort_cohort_client_client_note_path(cohort, cohort_client, unrelated_note)

      expect(response).to have_http_status(:not_found)
      expect(GrdaWarehouse::ClientNotes::CohortNote.exists?(unrelated_note.id)).to be(true)
    end

    context 'when the Client Notes column is read-only on the cohort' do
      before do
        columns = GrdaWarehouse::Cohort.available_columns
        columns.find { |c| c.is_a?(CohortColumns::ClientNotes) }.editable = false
        cohort.update!(column_state: columns)
      end

      it 'does not delete the note' do
        delete cohort_cohort_client_client_note_path(cohort, cohort_client, own_note)

        expect(response).to have_http_status(:redirect)
        expect(GrdaWarehouse::ClientNotes::CohortNote.exists?(own_note.id)).to be(true)
      end

      it 'does not create a note' do
        expect do
          post cohort_cohort_client_client_notes_path(cohort, cohort_client),
               params: { grda_warehouse_client_notes_cohort_note: { note: 'New note' } }
        end.not_to change(GrdaWarehouse::ClientNotes::CohortNote, :count)
      end
    end

    context 'when the user can view but not edit the cohort' do
      let(:viewer) { create(:acl_user) }

      before do
        setup_access_control(viewer, create(:cohort_client_viewer), all_cohorts_collection)
        # can_participate_in_cohorts granted on a collection that does not contain this cohort
        setup_access_control(viewer, create(:cohort_client_editor), create(:collection))
        sign_in viewer
      end

      it 'does not delete the note' do
        delete cohort_cohort_client_client_note_path(cohort, cohort_client, own_note)

        expect(response).to have_http_status(:redirect)
        expect(GrdaWarehouse::ClientNotes::CohortNote.exists?(own_note.id)).to be(true)
      end
    end
  end
end
