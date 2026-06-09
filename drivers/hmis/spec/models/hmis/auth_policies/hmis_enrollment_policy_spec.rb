# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisEnrollmentPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:other_project) { create(:hmis_hud_project, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, project: project, client: client, data_source: data_source) }
  let(:policy) { user.policy_for(enrollment, policy_type: :hmis_enrollment) }

  # Permissions required for viewing an enrollment
  let(:view_permissions) { [:can_view_enrollment_details, :can_view_project] }

  describe '#can_edit?' do
    it 'returns true if user can edit' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments, *view_permissions])
      expect(policy.can_edit?).to be true
    end

    it 'returns false if user only has can_edit_enrollments (missing permission requirements)' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments])
      expect(policy.can_edit?).to be false
    end

    it 'returns false if user can view but not edit' do
      create_access_control(user, project, with_permission: view_permissions)
      expect(policy.can_edit?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_edit_enrollments, *view_permissions])
      expect(policy.can_edit?).to be false
    end
  end

  describe '#can_delete?' do
    it 'returns true if user can delete' do
      create_access_control(user, project, with_permission: [:can_delete_enrollments, :can_edit_enrollments, *view_permissions])
      expect(policy.can_delete?).to be true
    end

    it 'returns false if user cannot delete' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments, *view_permissions])
      expect(policy.can_delete?).to be false
    end

    it 'returns false if user lacks can_edit_enrollments (missing permission requirements)' do
      create_access_control(user, project, with_permission: [:can_delete_enrollments, *view_permissions])
      expect(policy.can_delete?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_delete_enrollments, :can_edit_enrollments, *view_permissions])
      expect(policy.can_delete?).to be false
    end

    context 'enrollment is wip' do
      let(:enrollment) { create(:hmis_hud_wip_enrollment, project: project, client: client, data_source: data_source) }

      it 'returns true if user can edit' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments, *view_permissions])
        expect(policy.can_delete?).to be true
      end
    end
  end

  describe '#can_view_details?' do
    it 'returns true if user can view details' do
      create_access_control(user, project, with_permission: view_permissions)
      expect(policy.can_view_details?).to be true
    end

    it 'returns false if user cannot view the project (required for can_view_enrollment_details)' do
      create_access_control(user, project, with_permission: [:can_view_enrollment_details])
      expect(policy.can_view_details?).to be false
    end

    it 'returns false if user lacks can_view_enrollment_details, even if they can_view_limited_enrollment_details' do
      create_access_control(user, project.data_source, with_permission: [:can_view_project, :can_view_limited_enrollment_details])
      expect(policy.can_view_details?).to be false
    end
  end

  describe '#can_split_household?' do
    it 'returns true if user can split households at the enrollment project' do
      create_access_control(user, project, with_permission: [:can_split_households, *view_permissions])
      expect(policy.can_split_household?).to be true
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_split_households, *view_permissions])
      expect(policy.can_split_household?).to be false
    end
  end

  describe '#can_audit?' do
    it 'returns true if user can audit enrollments at the enrollment project' do
      create_access_control(user, project, with_permission: [:can_audit_enrollments, *view_permissions])
      expect(policy.can_audit?).to be true
    end

    it 'returns false if user lacks can_view_project (required for can_audit_enrollments)' do
      create_access_control(user, project, with_permission: [:can_audit_enrollments, :can_view_enrollment_details])
      expect(policy.can_audit?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_audit_enrollments, *view_permissions])
      expect(policy.can_audit?).to be false
    end
  end

  describe '#can_view_location_map?' do
    it 'returns true if user can view the enrollment location map at the enrollment project' do
      create_access_control(user, project, with_permission: [:can_view_enrollment_location_map, *view_permissions])
      expect(policy.can_view_location_map?).to be true
    end

    it 'returns false if user lacks can_view_project (required for can_view_enrollment_location_map)' do
      create_access_control(user, project, with_permission: [:can_view_enrollment_location_map, :can_view_enrollment_details])
      expect(policy.can_view_location_map?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_view_enrollment_location_map, *view_permissions])
      expect(policy.can_view_location_map?).to be false
    end
  end

  describe '#can_view_open_enrollment_summary?' do
    it 'returns true if user has can_view_open_enrollment_summary at the enrollment project' do
      create_access_control(user, project, with_permission: [:can_view_open_enrollment_summary, *view_permissions])
      expect(policy.can_view_open_enrollment_summary?).to be true
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_view_open_enrollment_summary, *view_permissions])
      expect(policy.can_view_open_enrollment_summary?).to be false
    end
  end

  describe '#can_create_file?' do
    it 'returns true when the user has can_manage_any_client_files on the enrollment project' do
      create_access_control(user, project, with_permission: [:can_manage_any_client_files])
      expect(policy.can_create_file?).to be true
    end

    it 'returns true when the user has can_manage_own_client_files' do
      create_access_control(user, project, with_permission: [:can_manage_own_client_files])
      expect(policy.can_create_file?).to be true
    end

    it 'returns true when the user has can_manage_own_client_files anywhere in the data source' do
      create_access_control(user, other_project, with_permission: [:can_manage_own_client_files])
      expect(policy.can_create_file?).to be true
    end

    it 'returns false when the user can only view files, not manage' do
      create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files])
      expect(policy.can_create_file?).to be false
    end

    it 'returns false when the user has can_manage_any_client_files only on a different project than the enrollment' do
      create_access_control(user, project, with_permission: [:can_view_clients])
      create_access_control(user, other_project, with_permission: [:can_view_clients, :can_manage_any_client_files])
      expect(policy.can_create_file?).to be false
    end
  end

  describe 'Global policy' do
    let(:global_policy) { user.policy_for(Hmis::Hud::Enrollment, policy_type: :hmis_enrollment) }

    it 'returns a Global policy instance when the resource is the class' do
      expect(global_policy).to be_a(Hmis::AuthPolicies::HmisEnrollmentPolicy::Global)
    end

    describe '#can_view?' do
      it 'is true when the user has both can_view_enrollment_details and can_view_project in the current data source' do
        create_access_control(user, project, with_permission: [:can_view_enrollment_details, :can_view_project])
        expect(global_policy.can_view?).to be true
      end

      it 'is true when the user has both can_view_enrollment_details and can_view_project, even at different projects' do
        # see comments on Hmis::AuthPolicies::UserContext#global_permissions
        create_access_control(user, project, with_permission: [:can_view_project])
        create_access_control(user, other_project, with_permission: [:can_view_enrollment_details])
        expect(global_policy.can_view?).to be true
      end

      it 'is false when the user only has can_view_enrollment_details' do
        create_access_control(user, project, with_permission: [:can_view_enrollment_details])
        expect(global_policy.can_view?).to be false
      end

      it 'is false when the user only has can_view_project' do
        create_access_control(user, project, with_permission: [:can_view_project])
        expect(global_policy.can_view?).to be false
      end

      it 'is false when the user has no permissions' do
        expect(global_policy.can_view?).to be false
      end

      it 'is false when the user has the permissions only in a different data source' do
        other_ds = create(:hmis_data_source)
        create_access_control(user, other_ds, with_permission: [:can_view_enrollment_details, :can_view_project])
        expect(global_policy.can_view?).to be false
      end
    end

    describe '#can_view_limited?' do
      it 'is true when the user has can_view_limited_enrollment_details in the current data source' do
        create_access_control(user, project, with_permission: [:can_view_limited_enrollment_details])
        expect(global_policy.can_view_limited?).to be true
      end

      it 'is false when the user has no permissions' do
        expect(global_policy.can_view_limited?).to be false
      end

      it 'is false when the user has can_view_limited_enrollment_details only in a different data source' do
        other_ds = create(:hmis_data_source)
        create_access_control(user, other_ds, with_permission: [:can_view_limited_enrollment_details])
        expect(global_policy.can_view_limited?).to be false
      end

      it 'is independent from can_view? (limited-only access does not grant can_view?)' do
        create_access_control(user, project, with_permission: [:can_view_limited_enrollment_details])
        expect(global_policy.can_view?).to be false
        expect(global_policy.can_view_limited?).to be true
      end
    end
  end

  context 'when policy is scoped to a different data source than the enrollment' do
    let!(:ds2) { create(:hmis_data_source) }
    let!(:ds2_user) { create(:hmis_user, data_source: ds2) }
    let(:policy) { ds2_user.policy_for(enrollment, policy_type: :hmis_enrollment) } # scoped to ds2

    it 'is denied' do
      expect(policy.can_edit?).to be false
      expect(policy.can_create_file?).to be false
    end

    context 'and user has permission in both data sources' do
      before do
        create_access_control(ds2_user, data_source, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        create_access_control(ds2_user, ds2, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      end

      it 'is still denied when scoped to the wrong data source' do
        expect(policy.can_edit?).to be false
        expect(policy.can_create_file?).to be false
      end

      it 'is allowed when scoped to the enrollment\'s data source' do
        ds2_user.hmis_data_source_id = data_source.id
        policy = ds2_user.policy_for(enrollment, policy_type: :hmis_enrollment)
        expect(policy.can_edit?).to be true
      end
    end
  end
end
