###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisUserPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  describe 'Instance' do
    let(:target_user) { create(:hmis_user, data_source: data_source) }
    let(:policy) { user.policy_for(target_user, policy_type: :hmis_user) }
    # Create an access control granting the target user some access in the data source
    let!(:target_user_access_control) { create_access_control(target_user, data_source, with_permission: :can_view_project) }

    describe '#can_view?' do
      it 'returns false without permissions' do
        expect(policy.can_view?).to be false
      end

      context 'when viewing self' do
        let(:target_user) { user }

        it 'returns true' do
          expect(policy.can_view?).to be true
        end
      end

      context 'with can_audit_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: :can_audit_users) }

        it 'returns true' do
          expect(policy.can_view?).to be true
        end
      end

      context 'with can_impersonate_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: :can_impersonate_users) }

        it 'returns true' do
          expect(policy.can_view?).to be true
        end
      end

      context 'when target user cannot access the viewer data source' do
        let(:other_data_source) { create(:hmis_data_source) }
        let!(:target_user_access_control) { create_access_control(target_user, other_data_source, with_permission: :can_view_project) }

        it 'returns false' do
          expect(policy.can_view?).to be false
        end
      end
    end

    describe '#can_audit?' do
      it 'returns false without permissions' do
        expect(policy.can_audit?).to be false
      end

      context 'with can_audit_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: :can_audit_users) }

        it 'returns true' do
          expect(policy.can_audit?).to be true
        end
      end
    end

    describe '#can_impersonate?' do
      it 'returns false without permissions' do
        expect(policy.can_impersonate?).to be false
      end

      context 'with can_impersonate_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: :can_impersonate_users) }

        it 'returns true' do
          expect(policy.can_impersonate?).to be true
        end

        context 'when trying to impersonate self' do
          let(:target_user) { user }

          it 'returns false' do
            expect(policy.can_impersonate?).to be false
          end
        end
      end
    end
  end

  describe 'Global' do
    let(:policy) { user.policy_for(Hmis::User, policy_type: :hmis_user) }

    describe '#can_impersonate_users?' do
      it 'returns false when user does not have can_impersonate_users permission' do
        expect(policy.can_impersonate_users?).to be false
      end

      context 'when user has can_impersonate_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_impersonate_users]) }

        it 'returns true' do
          expect(policy.can_impersonate_users?).to be true
        end
      end
    end

    describe '#can_audit_users?' do
      it 'returns false when user does not have can_audit_users permission' do
        expect(policy.can_audit_users?).to be false
      end

      context 'when user has can_audit_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_audit_users]) }

        it 'returns true' do
          expect(policy.can_audit_users?).to be true
        end
      end
    end

    describe '#can_index_application_users?' do
      it 'returns false without permissions' do
        expect(policy.can_index_application_users?).to be false
      end

      context 'when user has can_audit_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_audit_users]) }

        it 'returns true' do
          expect(policy.can_index_application_users?).to be true
        end
      end

      context 'when user has can_impersonate_users permission' do
        let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_impersonate_users]) }

        it 'returns true' do
          expect(policy.can_index_application_users?).to be true
        end
      end
    end

    describe '#can_view_user_picklist?' do
      it 'returns false without permissions' do
        expect(policy.can_view_user_picklist?).to be false
      end

      [
        [:can_audit_users],
        [:can_impersonate_users],
        [:can_administrate_config, :can_manage_forms, :can_configure_data_collection],
        [:can_audit_enrollments, :can_view_enrollment_details, :can_view_project],
        [:can_audit_clients],
        [:can_merge_clients, :can_view_clients],
      ].each do |permissions|
        permission = permissions.first

        context "with #{permission} permission" do
          let!(:access_control) { create_access_control(user, data_source, with_permission: permissions) }

          it 'returns true' do
            expect(policy.can_view_user_picklist?).to be true
          end
        end
      end
    end
  end
end
