###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::CohortPiiPolicy, type: :model do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:policy) { described_class.new(user: user) }

  it 'always shows name, photo, dob, hiv status, and the partial (masked) ssn -- cohorts have always shown these to anyone who can see the cohort' do
    expect(policy.can_view?).to be true
    expect(policy.can_view_name?).to be true
    expect(policy.can_view_photo?).to be true
    expect(policy.can_view_full_dob?).to be true
    expect(policy.can_view_hiv_status?).to be true
    expect(policy.can_view_partial_ssn?).to be true
  end

  describe '#can_view_full_ssn?' do
    # User#can_view_full_ssn? memoizes @permissions on the instance (a plain ||=, not
    # Memery), so this needs two separate users rather than granting the role mid-example.
    it 'is false for a user without the can_view_full_ssn role permission' do
      expect(policy.can_view_full_ssn?).to be false
    end

    it 'delegates to the viewer\'s global can_view_full_ssn? permission, the same gate ApplicationHelper#ssn applies' do
      collection = create(:collection)
      role = create(:role, can_view_full_ssn: true)
      setup_access_control(user, role, collection)

      expect(policy.can_view_full_ssn?).to be true
    end
  end
end
