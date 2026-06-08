# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::ProjectConfigPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:other_data_source) { create(:hmis_data_source) }

  describe 'Global#can_create?, #can_view?, and #can_manage?' do
    let(:policy) { user.policy_for(Hmis::ProjectConfig, policy_type: :project_config) }

    it 'returns false' do
      expect(policy.can_create?).to be false
      expect(policy.can_view?).to be false
      expect(policy.can_manage?).to be false
    end

    context 'when user has can_configure_data_collection in the data source' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }

      it 'returns true' do
        expect(policy.can_create?).to be true
        expect(policy.can_view?).to be true
        expect(policy.can_manage?).to be true
      end
    end

    context 'when user has permission in another data source' do
      let!(:access_control) { create_access_control(user, other_data_source, with_permission: [:can_configure_data_collection]) }

      it 'returns false' do
        expect(policy.can_create?).to be false
        expect(policy.can_view?).to be false
        expect(policy.can_manage?).to be false
      end
    end
  end

  describe 'Instance#can_update? and #can_destroy?' do
    let(:project) { create(:hmis_hud_project, data_source: data_source) }
    let(:project_config) { create(:hmis_project_auto_enter_config, project: project, data_source: data_source) }
    let(:policy) { user.policy_for(project_config, policy_type: :project_config) }

    it 'returns false' do
      expect(policy.can_update?).to be false
      expect(policy.can_destroy?).to be false
    end

    context 'when user has can_configure_data_collection' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }

      it 'returns true' do
        expect(policy.can_update?).to be true
        expect(policy.can_destroy?).to be true
      end
    end

    context 'when user has permission in another data source' do
      let!(:access_control) { create_access_control(user, other_data_source, with_permission: [:can_configure_data_collection]) }

      it 'returns false' do
        expect(policy.can_update?).to be false
        expect(policy.can_destroy?).to be false
      end
    end
  end
end
