###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::StaffAssignmentPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, hmis_data_source_id: data_source.id) }
  let(:policy) { user.policy_for(Hmis::StaffAssignment) }

  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }

  describe '#can_index?' do
    context 'when no project staff assignment configs exist anywhere' do
      it 'returns false' do
        expect(policy.can_index?).to be false
      end
    end

    context 'when project staff assignment configs exist' do
      let!(:config) { create(:hmis_project_staff_assignment_config, project: project) }

      it 'returns false if user has no access to any projects' do
        expect(policy.can_index?).to be false
      end

      it 'returns false if user has access to a project without a config' do
        unconfigured_project = create(:hmis_hud_project, data_source: data_source, organization: organization)
        create_access_control(user, unconfigured_project, with_permission: [:can_edit_enrollments])
        expect(policy.can_index?).to be false
      end

      it 'returns false if user has access to a configured project but with wrong permissions' do
        create_access_control(user, project, with_permission: [:can_view_project])
        expect(policy.can_index?).to be false
      end

      it 'returns true if user has access to a configured project with correct permissions' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments])
        expect(policy.can_index?).to be true
      end
    end
  end
end
