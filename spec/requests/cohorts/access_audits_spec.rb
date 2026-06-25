###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohort access audits', type: :request do
  let(:user) { create(:user) }
  let(:cohort) { create(:cohort) }

  before do
    allow_any_instance_of(User).to receive(:can_configure_cohorts?).and_return(true)
    allow_any_instance_of(User).to receive(:can_audit_users?).and_return(true)
    allow(GrdaWarehouse::Cohort).to receive(:viewable_by).and_return(GrdaWarehouse::Cohort.where(id: cohort.id))
    sign_in user
  end

  describe 'legacy access audit' do
    it 'renders for a user with both permissions' do
      get cohort_legacy_access_audit_path(cohort)
      expect(response).to be_successful
    end

    it 'exports CSV with the permissions note' do
      get export_cohort_legacy_access_audit_path(cohort, format: :csv)
      expect(response).to be_successful
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to include(Audit::CohortAccess::Base::PERMISSIONS_NOTE)
    end
  end

  describe 'acl access audit' do
    it 'renders for a user with both permissions' do
      get cohort_acl_access_audit_path(cohort)
      expect(response).to be_successful
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
