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

  let(:user) { create(:acl_user) }
  let(:cohort) { create(:cohort) }
  # A second, distinct user who actually holds a granted access path on the cohort, so
  # current_access has a row to iterate. The signed-in `user` above has no such grant, so a
  # cohort with only that user is empty and current_access's per-user checks never run.
  let(:member) { create(:user) }

  def role_with(*permissions)
    create(:role, **permissions.index_with { true })
  end

  def grant_acl(user, permissions, *records)
    collection = create(:collection)
    collection.set_viewables({ cohorts: records.map(&:id) })
    setup_access_control(user, role_with(*permissions), collection)
  end

  def grant_legacy(user, permissions, *records)
    access_group = create(:access_group)
    role_with(*permissions).add(user)
    access_group.add(user)
    records.each { |record| access_group.add_viewable(record) }
  end

  def refused?
    response.redirect? && !response.location.include?('/cohorts/')
  end

  before do
    Collection.maintain_system_groups
    sign_in user
  end

  describe 'legacy access audit' do
    before do
      grant_acl(user, [:can_view_cohorts, :can_configure_cohorts, :can_audit_users], cohort)
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
      grant_acl(user, [:can_view_cohorts, :can_configure_cohorts, :can_audit_users], cohort)
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
    let!(:other_cohort) { create(:cohort) }

    shared_examples 'audit authorization' do
      it 'denies a manager without can_audit_users' do
        grant(user, [:can_view_cohorts, :can_configure_cohorts], cohort)

        get cohort_legacy_access_audit_path(cohort)
        expect(refused?).to be(true)
        get cohort_acl_access_audit_path(cohort)
        expect(refused?).to be(true)
      end

      it 'denies a viewer with can_audit_users but no configure' do
        grant(user, [:can_view_cohorts, :can_audit_users], cohort)

        get cohort_legacy_access_audit_path(cohort)
        expect(refused?).to be(true)
        get export_cohort_acl_access_audit_path(cohort, format: :csv)
        expect(refused?).to be(true)
        expect(response.media_type).not_to eq('text/csv')
      end

      it 'allows a manager with can_audit_users' do
        grant(user, [:can_configure_cohorts, :can_audit_users], cohort)

        get cohort_legacy_access_audit_path(cohort)
        expect(response).to have_http_status(:ok)
        get cohort_acl_access_audit_path(cohort)
        expect(response).to have_http_status(:ok)
      end

      it 'denies a manager on a cohort outside the grant' do
        grant(user, [:can_configure_cohorts, :can_audit_users], cohort)

        get cohort_acl_access_audit_path(other_cohort)

        expect(refused?).to be(true)
      end

      it 'returns not found for a cohort that does not exist' do
        grant(user, [:can_configure_cohorts, :can_audit_users], cohort)

        get cohort_acl_access_audit_path(GrdaWarehouse::Cohort.maximum(:id) + 1)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an ACL user' do
      def grant(...) = grant_acl(...)

      include_examples 'audit authorization'
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }

      def grant(...) = grant_legacy(...)

      include_examples 'audit authorization'
    end
  end
end
