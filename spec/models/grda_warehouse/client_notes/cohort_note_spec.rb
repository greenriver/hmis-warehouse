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
  end
end
