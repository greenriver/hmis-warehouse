###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisClientPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:user) { create(:hmis_user, hmis_data_source_id: data_source.id) }
  let(:policy) { user.policy_for(client, policy_type: :hmis_client) }

  let(:granted_permissions) { [:can_view_clients, :can_edit_clients, :can_view_client_name, :can_view_any_nonconfidential_client_files] }

  shared_examples 'permission checks with access' do
    it 'grants configured permissions' do
      expect(policy.can_view?).to be true
      expect(policy.can_edit?).to be true
      expect(policy.can_view_name?).to be true
      expect(policy.can_index_files?).to be true
    end

    it 'denies unconfigured permissions' do
      expect(policy.can_delete?).to be false
      expect(policy.can_manage_alerts?).to be false
      expect(policy.can_create_file?).to be false
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all permissions when user lacks access' do
      expect(policy.can_view?).to be false
      expect(policy.can_edit?).to be false
      expect(policy.can_delete?).to be false
      expect(policy.can_view_name?).to be false
      expect(policy.can_manage_alerts?).to be false
      expect(policy.can_index_files?).to be false
      expect(policy.can_create_file?).to be false
    end
  end

  # cruft: user has full permissions in a different data source, which should not be returned in any of the examples
  let(:other_ds) { create(:hmis_data_source) }
  let!(:other_ds_access_control) { create_access_control(user, other_ds) }

  context 'Instance policy' do
    let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project) }

    context 'with project access' do
      let!(:access_control) { create_access_control(user, project, with_permission: granted_permissions) }

      include_examples 'permission checks with access'
    end

    context 'with organization access' do
      let!(:access_control) { create_access_control(user, organization, with_permission: granted_permissions) }

      include_examples 'permission checks with access'
    end

    context 'without any access' do
      let!(:other_project) { create(:hmis_hud_project, data_source: data_source) }
      let!(:access_control) { create_access_control(user, other_project, with_permission: granted_permissions) }

      include_examples 'permission checks without access'
    end

    describe '#can_index_files?' do
      context 'when user has can_manage_own_client_files via access on enrolled project' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_manage_own_client_files]) }

        it 'returns true' do
          expect(policy.can_index_files?).to be true
        end
      end

      context 'when user has can_manage_own_client_files only on a different project than the enrollment project' do
        let!(:other_project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
        let!(:access_control) { create_access_control(user, other_project, with_permission: [:can_manage_own_client_files]) }

        it 'returns true via global_permissions' do
          expect(policy.can_index_files?).to be true
        end
      end

      context 'when user has can_view_any_nonconfidential_client_files via access on enrolled project' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files]) }

        it 'returns true' do
          expect(policy.can_index_files?).to be true
        end
      end

      context 'when user has can_view_any_confidential_client_files via access on enrolled project' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_confidential_client_files]) }

        it 'returns true' do
          expect(policy.can_index_files?).to be true
        end
      end

      context 'when user lacks file-related permissions' do
        let!(:other_project) { create(:hmis_hud_project, data_source: data_source) }
        let!(:access_control) { create_access_control(user, other_project, with_permission: [:can_view_clients]) }

        it 'returns false' do
          expect(policy.can_index_files?).to be false
        end
      end

      context 'when user has can_view_any_nonconfidential_client_files only via access on another project the client is not enrolled in' do
        let!(:other_project) { create(:hmis_hud_project, data_source: data_source) }
        let!(:access_control) { create_access_control(user, other_project, with_permission: [:can_view_any_nonconfidential_client_files]) }

        it 'returns false' do
          expect(policy.can_index_files?).to be false
        end
      end
    end

    describe '#can_create_file?' do
      context 'when user has can_manage_own_client_files' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_manage_own_client_files]) }

        it 'returns true' do
          expect(policy.can_create_file?).to be true
        end
      end

      context 'when user can only view, not manage' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files]) }

        it 'returns false' do
          expect(policy.can_create_file?).to be false
        end
      end

      context 'when user can view and manage' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files]) }

        it 'returns true' do
          expect(policy.can_create_file?).to be true
        end
      end

      context 'when user can manage but not view (misconfigured permissions)' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_manage_any_client_files]) }

        it 'returns false' do
          expect(policy.can_create_file?).to be false
        end
      end
    end

    describe '#can_edit_some_enrollments?' do
      context 'when user can edit enrollments at an enrolled project' do
        let!(:access_control) do
          create_access_control(
            user,
            project,
            with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
          )
        end

        it 'returns true' do
          expect(policy.can_edit_some_enrollments?).to be true
        end
      end

      context 'when user can view but not edit enrollments at an enrolled project' do
        let!(:access_control) do
          create_access_control(
            user,
            project,
            with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details],
          )
        end

        it 'returns false' do
          expect(policy.can_edit_some_enrollments?).to be false
        end
      end

      context 'when user can edit enrollments only at a different project' do
        let!(:other_project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
        let!(:access_control) do
          create_access_control(
            user,
            other_project,
            with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
          )
        end

        it 'returns false' do
          expect(policy.can_edit_some_enrollments?).to be false
        end
      end
    end
  end

  context 'when client has no enrollments' do
    context 'with global permissions (granted via any access control)' do
      let!(:access_control) { create_access_control(user, project, with_permission: granted_permissions) }

      include_examples 'permission checks with access'
    end

    context 'without any permissions' do
      include_examples 'permission checks without access'
    end

    describe '#can_edit_some_enrollments?' do
      let!(:access_control) do
        create_access_control(
          user,
          project,
          with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
        )
      end

      it 'returns true if user has enrollment edit permission anywhere' do
        expect(policy.can_edit_some_enrollments?).to be true
      end
    end
  end

  context 'Global policy' do
    let(:policy) { user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client) }

    context 'without any permissions' do
      it 'denies can_create?' do
        expect(policy.can_create?).to be false
      end

      it 'denies can_edit?' do
        expect(policy.can_edit?).to be false
      end

      it 'denies can_merge_clients?' do
        expect(policy.can_merge_clients?).to be false
      end
    end

    context 'with can_edit_clients permission' do
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_edit_clients]) }

      it 'grants can_create?' do
        expect(policy.can_create?).to be true
      end

      it 'grants can_edit?' do
        expect(policy.can_edit?).to be true
      end
    end

    context 'with can_merge_clients permission' do
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_merge_clients]) }

      it 'grants can_merge_clients?' do
        expect(policy.can_merge_clients?).to be true
      end
    end

    describe '#can_view_dob?' do
      it 'denies when user lacks can_view_dob permission' do
        expect(policy.can_view_dob?).to be false
      end

      context 'with can_view_dob permission' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_dob]) }

        it 'grants can_view_dob?' do
          expect(policy.can_view_dob?).to be true
        end
      end
    end

    describe '#can_view_client_alerts?' do
      it 'denies when user lacks can_view_client_alerts permission' do
        expect(policy.can_view_client_alerts?).to be false
      end

      context 'with can_view_client_alerts permission' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_client_alerts]) }

        it 'grants can_view_client_alerts?' do
          expect(policy.can_view_client_alerts?).to be true
        end
      end
    end
  end
end
