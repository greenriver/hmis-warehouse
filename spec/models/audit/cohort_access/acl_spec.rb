###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Audit::CohortAccess::Acl do
  include AccessControlSetup

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
  let(:role) { create(:role) }
  let(:collection) { create(:collection) }
  let(:t1) { Time.zone.parse('2025-01-01 12:00:00') }
  let(:t2) { Time.zone.parse('2025-02-01 12:00:00') }

  subject(:audit) { described_class.new(cohort.reload) }

  def current_user_ids
    audit.current_access.users.map(&:id)
  end

  # Wire the full ACL chain: cohort -> Collection (GVE) and user -> UserGroup -> AccessControl -> Collection
  def grant_acl_access!
    collection.add_viewable(cohort)
    setup_access_control(user, role, collection)
  end

  describe 'access via the ACL chain' do
    before { travel_to(t1) { grant_acl_access! } }

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

    it 'identifies the ACL model' do
      expect(audit.model_label).to match(/acl|collection/i)
    end
  end

  describe 'revoking access by removing the user from the user group' do
    before do
      travel_to(t1) { grant_acl_access! }
      travel_to(t2) do
        user_group = UserGroup.find_by(name: "#{role.name} x #{collection.name}")
        user_group.remove(user)
      end
    end

    it 'no longer reports current access' do
      expect(current_user_ids).not_to include(user.id)
    end

    it 'records a revoke event for the user' do
      revokes = audit.events.select { |e| e.effect == :revoked && e.affected_user&.id == user.id }
      expect(revokes).not_to be_empty
    end
  end

  describe 'revoking access by destroying the access control' do
    before do
      travel_to(t1) { grant_acl_access! }
      travel_to(t2) do
        AccessControl.find_by(collection_id: collection.id).destroy
      end
    end

    it 'no longer reports current access' do
      expect(current_user_ids).not_to include(user.id)
    end
  end

  describe 'revoking access by removing the cohort from the collection' do
    before do
      travel_to(t1) { grant_acl_access! }
      travel_to(t2) { collection.remove_viewable(cohort) }
    end

    it 'no longer reports current access' do
      expect(current_user_ids).not_to include(user.id)
    end
  end
end
