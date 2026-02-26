###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisProjectPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:policy) { user.policy_for(project, policy_type: :hmis_project) }

  shared_examples 'permission checks with access' do
    it 'grants configured permissions' do
      expect(policy.can_view?).to be true
      expect(policy.can_edit?).to be true
    end

    it 'denies unconfigured permissions' do
      expect(policy.can_destroy?).to be false
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all permissions when user lacks access' do
      expect(policy.can_view?).to be false
      expect(policy.can_edit?).to be false
      expect(policy.can_destroy?).to be false
    end
  end

  describe 'basic permission checks with permission granted through different entities' do
    context 'with direct project access' do
      before do
        create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
      end
      include_examples 'permission checks with access'
    end

    context 'with organization access' do
      before do
        create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details])
      end
      include_examples 'permission checks with access'
    end

    context 'with data source access' do
      before do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
      end
      include_examples 'permission checks with access'
    end

    context 'with project group access' do
      let(:project_group) do
        group = create(:hmis_project_group)
        project.project_groups << group
        project.save!
        group
      end

      before do
        create_access_control(user, project_group, with_permission: [:can_view_project, :can_edit_project_details])
      end

      include_examples 'permission checks with access'
    end

    context 'without any access' do
      include_examples 'permission checks without access'
    end

    context 'when project belongs to a different data source' do
      let(:other_data_source) { create(:hmis_data_source) }
      before do
        # grant user access to the project
        create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
        # link user to the other data source
        user.hmis_data_source_id = other_data_source.id
      end

      it 'is denied' do
        expect(policy.can_view?).to be false
      end

      it 'reports the mismatch to Sentry' do
        expect(Sentry).to receive(:capture_message).with(/HMIS Data Source Mismatch/)
        policy.can_view?
      end
    end
  end

  describe '#can_create_enrollments?' do
    context 'with can_edit_enrollments permission' do
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_enrollment_details, :can_view_project, :can_edit_enrollments]) }

      it 'returns true' do
        expect(policy.can_create_enrollments?).to be true
      end
    end

    context 'without can_edit_enrollments permission (even if it is granted at another project)' do
      let!(:other_project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
      let!(:access_control) { create_access_control(user, other_project, with_permission: [:can_view_enrollment_details, :can_view_project, :can_edit_enrollments]) }

      it 'returns false' do
        expect(policy.can_create_enrollments?).to be false
      end
    end
  end

  describe '#can_create_and_enroll_new_clients?' do
    it 'returns true when user can create and enroll new clients' do
      create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details, :can_edit_enrollments])
      expect(policy.can_create_and_enroll_new_clients?).to be true
    end

    it 'returns false when user cannot create clients' do
      create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_view_enrollment_details, :can_edit_enrollments])
      expect(policy.can_create_and_enroll_new_clients?).to be false
    end

    it 'returns false when user cannot enroll clients' do
      create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details])
      expect(policy.can_create_and_enroll_new_clients?).to be false
    end

    context 'when user can create clients in a different project, but not this one' do
      let(:p2) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
      before(:each) do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_view_enrollment_details, :can_edit_enrollments])
        create_access_control(user, p2, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients])
      end

      it 'still returns false' do
        expect(policy.can_create_and_enroll_new_clients?).to be false
      end
    end
  end
end
