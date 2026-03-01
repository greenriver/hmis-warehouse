###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  let(:granted_permissions) { [:can_view_clients, :can_edit_clients, :can_view_client_name] }

  shared_examples 'permission checks with access' do
    it 'grants configured permissions' do
      expect(policy.can_view?).to be true
      expect(policy.can_edit?).to be true
      expect(policy.can_view_name?).to be true
    end

    it 'denies unconfigured permissions' do
      expect(policy.can_destroy?).to be false
      expect(policy.can_manage_alerts?).to be false
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all permissions when user lacks access' do
      expect(policy.can_view?).to be false
      expect(policy.can_edit?).to be false
      expect(policy.can_destroy?).to be false
      expect(policy.can_view_name?).to be false
      expect(policy.can_manage_alerts?).to be false
    end
  end

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
  end

  context 'when client has no enrollments' do
    context 'with global permissions (granted via any access control)' do
      let!(:access_control) { create_access_control(user, project, with_permission: granted_permissions) }

      include_examples 'permission checks with access'
    end

    context 'without any permissions' do
      include_examples 'permission checks without access'
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
  end
end
