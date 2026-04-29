# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::AuthPolicies::ServiceTypePolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:category) { create(:hmis_custom_service_category, data_source: data_source) }
  let(:service_type) { create(:hmis_custom_service_type, custom_service_category: category, data_source: data_source) }
  let(:hud_service_type) { create(:hmis_hud_custom_service_type, hud_record_type: 141, hud_type_provided: 1, custom_service_category: category, data_source: data_source) }
  let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_configure_data_collection]) }

  describe 'Instance#can_destroy?' do
    it 'returns true when permitted' do
      expect(service_type.hud_service?).to be false
      policy = user.policy_for(service_type, policy_type: :service_type)
      expect(policy.can_destroy?).to be true
    end

    it 'returns false for HUD-managed service types' do
      expect(hud_service_type.hud_service?).to be true
      policy = user.policy_for(hud_service_type, policy_type: :service_type)
      expect(policy.can_destroy?).to be false
    end

    it 'returns false when not permitted' do
      remove_permissions(access_control, :can_configure_data_collection)
      expect(user.policy_for(service_type, policy_type: :service_type).can_destroy?).to be false
    end
  end
end
