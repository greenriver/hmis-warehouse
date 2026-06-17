###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::AuthPolicies::HmisCustomAssessmentPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:other_project) { create(:hmis_hud_project, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, project: project, client: client, data_source: data_source) }

  describe 'Instance#can_delete?' do
    describe 'when assessment is still in-progress (wip)' do
      let(:assessment) { create(:hmis_wip_custom_assessment, data_source: data_source, enrollment: enrollment, client: client) }
      let(:policy) { user.policy_for(assessment, policy_type: :hmis_custom_assessment) }

      it 'returns true if user has can_edit_enrollments with requirements' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be true
      end

      it 'returns false if user lacks can_edit_enrollments' do
        create_access_control(
          user,
          project,
          with_permission: [:can_delete_assessments, :can_view_enrollment_details, :can_view_project],
        )
        expect(policy.can_delete?).to be false
      end

      it 'returns false if user has permissions only on a different project' do
        create_access_control(user, other_project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be false
      end

      it 'returns false if user cannot view the record' do
        # user's permissions were set up incorrectly: they can edit enrollments in this project, but they can't view enrollments (don't have dependent permissions)
        create_access_control(user, project, with_permission: [:can_edit_enrollments])
        # user has full permissions in a different project
        create_access_control(user, other_project)
        expect(policy.can_delete?).to be false
      end
    end

    describe 'when assessment is intake and submitted (not wip)' do
      let(:assessment) { create(:hmis_intake_assessment, data_source: data_source, enrollment: enrollment, client: client) }
      let(:policy) { user.policy_for(assessment, policy_type: :hmis_custom_assessment) }

      it 'returns true if user has can_delete_enrollments with requirements' do
        create_access_control(
          user,
          project,
          with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project, :can_delete_enrollments],
        )
        expect(policy.can_delete?).to be true
      end

      it 'returns false if user has can_edit but not can_delete_enrollments' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be false
      end
    end

    describe 'when assessment is submitted (non-intake)' do
      let(:assessment) do
        create(
          :hmis_custom_assessment,
          data_source: data_source,
          enrollment: enrollment,
          client: client,
          wip: false,
          data_collection_stage: 5, # annual
        )
      end
      let(:policy) { user.policy_for(assessment, policy_type: :hmis_custom_assessment) }

      it 'returns true if user has can_delete_assessments with requirements' do
        create_access_control(
          user,
          project,
          with_permission: [:can_delete_assessments, :can_view_enrollment_details, :can_view_project],
        )
        expect(policy.can_delete?).to be true
      end

      it 'returns false if user lacks can_delete_assessments' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be false
      end

      it 'returns false if user has permissions only on a different project' do
        create_access_control(user, other_project, with_permission: [:can_delete_assessments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be false
      end
    end
  end
end
