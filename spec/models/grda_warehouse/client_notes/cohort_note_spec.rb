###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientNotes::CohortNote, type: :model do
  describe '#destroyable_by' do
    let(:user) { create(:acl_user) }
    let(:client) { create(:grda_warehouse_hud_client) }
    let(:note_cohort) { create(:cohort) }
    let(:unrelated_cohort) { create(:cohort) }
    let(:note) { described_class.create!(client: client, user: create(:user), note: 'A note') }

    before do
      Collection.maintain_system_groups
      GrdaWarehouse::CohortClient.create!(cohort: note_cohort, client: client)
      GrdaWarehouse::CohortClient.create!(cohort: unrelated_cohort, client: create(:grda_warehouse_hud_client))
    end

    def grant(permissions, cohort)
      collection = create(:collection)
      collection.set_viewables({ cohorts: [cohort.id] })
      setup_access_control(user, create(:role, **permissions.index_with { true }), collection)
    end

    it 'allows a user who can edit clients on a cohort the client is on' do
      grant([:can_view_cohorts, :can_participate_in_cohorts], note_cohort)

      expect(note.destroyable_by(user)).to be(true)
    end

    it 'refuses a user whose edit permission is on a cohort the client is not on' do
      grant([:can_view_cohorts], note_cohort)
      grant([:can_view_cohorts, :can_participate_in_cohorts], unrelated_cohort)

      expect(note.destroyable_by(user)).to be(false)
    end

    it 'refuses a user who can only view the client cohort' do
      grant([:can_view_cohorts], note_cohort)

      expect(note.destroyable_by(user)).to be(false)
    end

    it 'allows a user who can edit clients on a cohort the client was removed from' do
      grant([:can_view_cohorts, :can_participate_in_cohorts], note_cohort)
      GrdaWarehouse::CohortClient.find_by!(cohort: note_cohort, client: client).destroy

      expect(note.destroyable_by(user)).to be(true)
    end

    it 'refuses a user who can edit clients only on an unrelated cohort when the client was removed' do
      grant([:can_view_cohorts, :can_participate_in_cohorts], unrelated_cohort)
      GrdaWarehouse::CohortClient.find_by!(cohort: note_cohort, client: client).destroy

      expect(note.destroyable_by(user)).to be(false)
    end

    it 'runs no queries for the second note when the notes are loaded through one client' do
      grant([:can_view_cohorts, :can_participate_in_cohorts], note_cohort)
      2.times { described_class.create!(client: client, user: create(:user), note: 'A note') }
      first_note, second_note = GrdaWarehouse::Hud::Client.find(client.id).cohort_notes.to_a

      expect(first_note.destroyable_by(user)).to be(true)
      second_result = nil
      expect(count_database_queries { second_result = second_note.destroyable_by(user) }).to eq(0)
      expect(second_result).to be(true)
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }

      def grant_legacy(permissions, *cohorts)
        access_group = create(:access_group)
        create(:role, **permissions.index_with { true }).add(user)
        access_group.add(user)
        cohorts.each { |cohort| access_group.add_viewable(cohort) }
      end

      it 'allows a participant with access to the client cohort' do
        grant_legacy([:can_view_cohorts, :can_participate_in_cohorts], note_cohort)

        expect(note.destroyable_by(user)).to be(true)
      end

      it 'refuses a participant whose access is to a cohort the client is not on' do
        grant_legacy([:can_view_cohorts, :can_participate_in_cohorts], unrelated_cohort)

        expect(note.destroyable_by(user)).to be(false)
      end
    end
  end
end
