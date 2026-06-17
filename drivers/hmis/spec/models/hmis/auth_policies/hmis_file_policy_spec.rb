###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::AuthPolicies::HmisFilePolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:other_project) { create(:hmis_hud_project, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:other_user) { create(:hmis_user, data_source: data_source) }

  def file_policy(file)
    user.policy_for(file, policy_type: :hmis_file)
  end

  describe 'Instance policy' do
    let!(:enrollment) { create(:hmis_hud_enrollment, project: project, client: client, data_source: data_source) }

    let(:file) { create(:file, :skip_validate, client: client, user: other_user, confidential: false) }
    let(:confidential_file) { create(:file, :skip_validate, client: client, user: other_user, confidential: true) }
    let(:own_file) { create(:file, :skip_validate, client: client, user: user) }

    describe '#can_view_unredacted?' do
      context 'when user can view non-confidential files' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files]) }

        it 'grants view access to non-confidential files' do
          expect(file_policy(file).can_view_unredacted?).to be true
          expect(file_policy(own_file).can_view_unredacted?).to be true
          expect(file_policy(confidential_file).can_view_unredacted?).to be false
        end
      end

      context 'when user can view confidential files' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_confidential_client_files]) }

        it 'grants view access to confidential files' do
          expect(file_policy(confidential_file).can_view_unredacted?).to be true
        end
      end

      context 'when user can manage own files' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_manage_own_client_files]) }

        it 'grants view access to own files' do
          expect(file_policy(own_file).can_view_unredacted?).to be true
          expect(file_policy(file).can_view_unredacted?).to be false
          expect(file_policy(confidential_file).can_view_unredacted?).to be false
        end
      end

      context 'when the user has manage permission but not view (misconfigured)' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_manage_any_client_files]) }

        it 'denies view access' do
          expect(file_policy(file).can_view_unredacted?).to be false
          expect(file_policy(confidential_file).can_view_unredacted?).to be false
          expect(file_policy(own_file).can_view_unredacted?).to be false
        end
      end

      context "when the user does not have file access for the file's enrollment's project" do
        let!(:other_enrollment) { create(:hmis_hud_enrollment, project: other_project, client: client, data_source: data_source) }
        let!(:other_enrollment_file) { create(:file, :skip_validate, client: client, user: other_user, enrollment: other_enrollment, confidential: false) }
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files]) }

        it 'denies view access' do
          expect(file_policy(other_enrollment_file).can_view_unredacted?).to be false
        end
      end
    end

    describe '#can_edit? and #can_delete?' do
      context 'when user can only view' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files]) }

        it 'denies edit and delete access' do
          expect(file_policy(file).can_edit?).to be false
          expect(file_policy(confidential_file).can_edit?).to be false
          expect(file_policy(own_file).can_edit?).to be false
          expect(file_policy(file).can_delete?).to be false
          expect(file_policy(confidential_file).can_delete?).to be false
          expect(file_policy(own_file).can_delete?).to be false
        end
      end

      context 'when user can manage own files' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_manage_own_client_files]) }

        it 'grants edit and delete access to own files' do
          expect(file_policy(own_file).can_edit?).to be true
          expect(file_policy(file).can_edit?).to be false
          expect(file_policy(confidential_file).can_edit?).to be false
          expect(file_policy(own_file).can_delete?).to be true
          expect(file_policy(file).can_delete?).to be false
          expect(file_policy(confidential_file).can_delete?).to be false
        end
      end

      context 'when user can manage any files in the project (meaning all files they can view, they can manage)' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_view_any_confidential_client_files, :can_manage_any_client_files]) }

        it 'grants edit and delete access to all files in the project' do
          expect(file_policy(file).can_edit?).to be true
          expect(file_policy(confidential_file).can_edit?).to be true
          expect(file_policy(own_file).can_edit?).to be true
          expect(file_policy(file).can_delete?).to be true
          expect(file_policy(confidential_file).can_delete?).to be true
          expect(file_policy(own_file).can_delete?).to be true
        end
      end

      context 'when user can manage any and view non-confidential but the file is confidential' do
        let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files]) }

        it 'only allows editing and deleting non-confidential files' do
          expect(file_policy(confidential_file).can_edit?).to be false
          expect(file_policy(confidential_file).can_delete?).to be false
        end
      end
    end
  end

  describe 'Global policy' do
    let(:policy) { user.policy_for(Hmis::File, policy_type: :hmis_file) }

    describe '#can_manage_own_client_files?' do
      it 'returns false without access' do
        expect(policy.can_manage_own_client_files?).to be false
      end

      it 'returns true when the user has can_manage_own_client_files anywhere in the data source' do
        create_access_control(user, project, with_permission: [:can_manage_own_client_files])
        expect(policy.can_manage_own_client_files?).to be true
      end
    end

    describe '#can_index?' do
      it 'returns false without file-related global permissions' do
        expect(policy.can_index?).to be false
      end

      it 'returns true when the user has can_manage_own_client_files anywhere in the data source' do
        create_access_control(user, project, with_permission: [:can_manage_own_client_files])
        expect(policy.can_index?).to be true
      end

      it 'returns true when the user has can_view_any_nonconfidential_client_files anywhere in the data source' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files])
        expect(policy.can_index?).to be true
      end

      it 'returns true when the user has can_view_any_confidential_client_files anywhere in the data source' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_view_any_confidential_client_files])
        expect(policy.can_index?).to be true
      end

      it 'returns false when the user can only manage, not view (misconfigured permissions)' do
        create_access_control(user, project, with_permission: [:can_manage_any_client_files])
        expect(policy.can_index?).to be false
      end
    end
  end
end
