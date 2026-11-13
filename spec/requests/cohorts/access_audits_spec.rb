###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohort access audits', type: :request do
  include AccessControlSetup

  # The audit reconstructs access from PaperTrail versions, which are disabled by default in specs.
  around(:each) { |example| PaperTrailHelper.with_paper_trail { example.run } }

  let(:user) { create(:user) }
  let(:cohort) { create(:cohort) }
  # A second, distinct user who actually holds a granted access path on the cohort, so
  # current_access has a row to iterate. The signed-in `user` above has no such grant, so a
  # cohort with only that user is empty and current_access's per-user checks never run.
  let(:member) { create(:user) }

  before do
    allow_any_instance_of(User).to receive(:can_configure_cohorts?).and_return(true)
    allow_any_instance_of(User).to receive(:can_audit_users?).and_return(true)
    allow(GrdaWarehouse::Cohort).to receive(:viewable_by).and_return(GrdaWarehouse::Cohort.where(id: cohort.id))
    sign_in user
  end

  describe 'legacy access audit' do
    before do
      group = create(:access_group)
      group.add_viewable(cohort)
      group.add(member)
    end

    it 'renders for a user with both permissions' do
      get cohort_legacy_access_audit_path(cohort)
      expect(response).to be_successful
      expect(response.body).to include(member.name)
    end

    it 'exports CSV with the permissions note' do
      get export_cohort_legacy_access_audit_path(cohort, format: :csv)
      expect(response).to be_successful
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to include(Audit::CohortAccess::Base::PERMISSIONS_NOTE)
      expect(response.body).to include(member.name)
    end
  end

  describe 'acl access audit' do
    before do
      role = create(:role)
      collection = create(:collection)
      collection.add_viewable(cohort)
      setup_access_control(member, role, collection)
    end

    it 'renders for a user with both permissions' do
      get cohort_acl_access_audit_path(cohort)
      expect(response).to be_successful
      expect(response.body).to include(member.name)
    end
  end

  describe 'authorization' do
    it 'denies a user without can_audit_users' do
      allow_any_instance_of(User).to receive(:can_audit_users?).and_return(false)
      get cohort_legacy_access_audit_path(cohort)
      expect(response).to have_http_status(:redirect)
    end

    it 'denies a user without can_configure_cohorts' do
      allow_any_instance_of(User).to receive(:can_configure_cohorts?).and_return(false)
      get cohort_acl_access_audit_path(cohort)
      expect(response).to have_http_status(:redirect)
    end
  end
end
