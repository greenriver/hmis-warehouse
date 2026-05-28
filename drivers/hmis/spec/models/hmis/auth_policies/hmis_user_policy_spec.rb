# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisUserPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:policy) { user.policy_for(Hmis::User, policy_type: :hmis_user) }

  describe 'Global' do
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
  end
end
