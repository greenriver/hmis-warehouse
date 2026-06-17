###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Audit::CohortAccess::Legacy do
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
  let(:t1) { Time.zone.parse('2025-01-01 12:00:00') }
  let(:t2) { Time.zone.parse('2025-02-01 12:00:00') }

  subject(:audit) { described_class.new(cohort.reload) }

  def current_user_ids
    audit.current_access.users.map(&:id)
  end

  describe 'access via a general access group' do
    let(:group) { create(:access_group) }

    before do
      travel_to(t1) do
        group.add_viewable(cohort)
        group.add(user)
      end
    end

    it 'reports the user as currently having access' do
      expect(current_user_ids).to include(user.id)
    end

    it 'counts at least one granting path' do
      expect(audit.current_access.path_count).to be >= 1
    end

    it 'records a grant event for the user' do
      grants = audit.events.select { |e| e.effect == :granted && e.affected_user&.id == user.id }
      expect(grants).not_to be_empty
    end
  end

  describe 'revoking access by removing the user from the group' do
    let(:group) { create(:access_group) }

    before do
      travel_to(t1) do
        group.add_viewable(cohort)
        group.add(user)
      end
      travel_to(t2) { group.remove(user) }
    end

    it 'no longer reports current access' do
      expect(current_user_ids).not_to include(user.id)
    end

    it 'records a revoke event for the user' do
      revokes = audit.events.select { |e| e.effect == :revoked && e.affected_user&.id == user.id }
      expect(revokes).not_to be_empty
    end
  end

  describe 'personal access group (implicit membership, no AccessGroupMember)' do
    before do
      travel_to(t1) { user.add_viewable(cohort) }
    end

    it 'reports the owner as currently having access via the personal group' do
      expect(current_user_ids).to include(user.id)
    end
  end

  describe 'redundant access via two groups' do
    let(:group_a) { create(:access_group) }
    let(:group_b) { create(:access_group) }

    before do
      travel_to(t1) do
        [group_a, group_b].each do |group|
          group.add_viewable(cohort)
          group.add(user)
        end
      end
      travel_to(t2) { group_a.remove(user) }
    end

    it 'still reports current access because the other group still grants it' do
      expect(current_user_ids).to include(user.id)
    end

    it 'labels the removal from the redundant group as no-effect, not a revoke' do
      user_events = audit.events.select { |e| e.affected_user&.id == user.id }
      expect(user_events.map(&:effect)).to include(:no_effect)
      expect(user_events.map(&:effect)).not_to include(:revoked)
    end
  end

  describe 'model_label' do
    it 'identifies the legacy model' do
      expect(audit.model_label).to match(/legacy/i)
    end
  end
end
