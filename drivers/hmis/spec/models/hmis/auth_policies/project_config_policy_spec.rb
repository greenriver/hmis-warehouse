# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::ProjectConfigPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  describe 'Global#can_manage?' do
    let(:policy) { user.policy_for(Hmis::ProjectConfig, policy_type: :project_config) }

    context 'when user has can_configure_data_collection in the data source' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }

      it 'returns true' do
        expect(policy.can_manage?).to be true
      end
    end

    context 'when user lacks can_configure_data_collection in the data source' do
      let!(:access_control) { create_access_control(user, data_source, without_permission: [:can_configure_data_collection]) }

      it 'returns false' do
        expect(policy.can_manage?).to be false
      end
    end
  end
end
