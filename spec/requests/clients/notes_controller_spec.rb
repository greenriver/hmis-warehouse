###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../app/models/grda_warehouse/client_notes/base'
require_relative '../../../app/models/grda_warehouse/client_notes/chronic_justification'

RSpec.describe Clients::NotesController, type: :request do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  let!(:admin) { create :acl_user }
  let!(:admin_role) { create :admin_role }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }
  let!(:chronic_justification) { create :grda_warehouse_client_notes_chronic_justification, client: client }
  let!(:initial_note_count) { GrdaWarehouse::ClientNotes::ChronicJustification.count }
  let!(:no_data_source_collection) { create :collection }

  before do
    sign_in admin
    Collection.maintain_system_groups
    setup_access_control(admin, admin_role, Collection.system_collection(:data_sources))
  end

  describe 'DELETE #destroy' do
    it 'deletes the note' do
      expect { delete client_note_path(chronic_justification.client, chronic_justification) }.to change(GrdaWarehouse::ClientNotes::ChronicJustification, :count).by(-1)
    end

    it 'redirects to Client/#show' do
      delete client_note_path(chronic_justification.client, chronic_justification)
      expect(response).to redirect_to(client_notes_path(chronic_justification.client.id))
    end
  end

  describe 'DELETE #destroy of a cohort note' do
    let!(:cohort) { create(:cohort) }
    let!(:cohort_note) { GrdaWarehouse::ClientNotes::CohortNote.create!(client: client, user: admin, note: 'Cohort note') }
    let!(:cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: client) }

    def grant_cohort_update(user, cohort)
      collection = create(:collection)
      collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(user, create(:role, can_view_cohorts: true, can_participate_in_cohorts: true), collection)
    end

    it 'keeps the note when the user can not update data on any cohort the client is on' do
      expect { delete client_note_path(client, cohort_note) }.not_to change(GrdaWarehouse::ClientNotes::CohortNote, :count)
      expect(flash[:error]).to eq('You do not have permission to delete this note.')
    end

    it 'deletes the note when the user can update data on a cohort the client is on' do
      grant_cohort_update(admin, cohort)

      expect { delete client_note_path(client, cohort_note) }.to change(GrdaWarehouse::ClientNotes::CohortNote, :count).by(-1)
    end

    it 'deletes the note when the client was removed from the cohort the user can update' do
      grant_cohort_update(admin, cohort)
      cohort_client.destroy

      expect { delete client_note_path(client, cohort_note) }.to change(GrdaWarehouse::ClientNotes::CohortNote, :count).by(-1)
    end
  end

  describe 'POST #create_note' do
    context 'with valid attributes' do
      before do
        post client_notes_path(client), params: { note: attributes_for(:grda_warehouse_client_notes_chronic_justification) }
      end

      it 'creates client note' do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count + 1)
      end

      it 'redirects to #show' do
        expect(response).to redirect_to(client_notes_path(client.id))
      end

      it 'flashes notice' do
        expect(flash[:notice]).to be_present
      end
    end

    context 'with invalid attributes' do
      before { post client_notes_path(client), params: { note: { note: '' } } } # invalid because note is an empty string

      it 'does not save the new contact' do
        expect(GrdaWarehouse::ClientNotes::ChronicJustification.count).to eq(initial_note_count)
      end

      it 're-renders #show' do
        expect(response).to redirect_to(client_notes_path(client.id))
      end

      it 'flashes error' do
        expect(flash[:error]).to be_present
      end
    end
  end
end
