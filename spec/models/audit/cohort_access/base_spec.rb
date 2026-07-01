###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Exercises the shared Base behavior (CSV export + permissions note) through the Legacy subclass.
RSpec.describe Audit::CohortAccess::Base do
  around(:each) do |example|
    PaperTrailHelper.with_paper_trail do
      PaperTrail.request.enabled = true
      example.run
    ensure
      PaperTrail.request.enabled = false
    end
  end

  let(:cohort) { create(:cohort) }
  let(:user) { create(:user) }
  let(:group) { create(:access_group) }

  subject(:audit) { Audit::CohortAccess::Legacy.new(cohort.reload) }

  before do
    travel_to(Time.zone.parse('2025-01-01 12:00:00')) do
      group.add_viewable(cohort)
      group.add(user)
    end
  end

  describe '#to_csv' do
    let(:csv) { audit.to_csv }

    it 'includes the permissions disclaimer note' do
      expect(csv).to include(Audit::CohortAccess::Base::PERMISSIONS_NOTE)
    end

    it 'includes a header row with the enriched columns' do
      expect(csv).to include('Affected User', 'Effect', 'Path')
    end

    it 'includes a row naming the affected user and a grant effect' do
      expect(csv).to include(user.name)
      expect(csv).to match(/Granted/)
    end
  end

  describe '#current_access' do
    it 'returns user_accesses with path labels for each active user' do
      ua = audit.current_access.user_accesses.find { |a| a.user.id == user.id }
      expect(ua).to be_present
      expect(ua.path_labels).to all(be_a(String))
    end

    it 'excludes soft-deleted users' do
      user.update_column(:deleted_at, Time.current)
      expect(audit.current_access.users.map(&:id)).not_to include(user.id)
    end

    it 'excludes the system user from current access' do
      system_user = User.system_user
      travel_to(Time.zone.parse('2025-01-01 12:00:00')) { group.add(system_user) }
      expect(audit.current_access.users.map(&:id)).not_to include(system_user.id)
    end
  end

  describe '#events' do
    it 'excludes events where the only affected user is the system user' do
      system_user = User.system_user
      travel_to(Time.zone.parse('2025-01-01 13:00:00')) { group.add(system_user) }
      system_events = audit.events.select { |e| e.affected_user&.id == system_user.id }
      expect(system_events).to be_empty
    end
  end
end
