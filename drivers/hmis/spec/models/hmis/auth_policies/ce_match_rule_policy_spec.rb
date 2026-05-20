# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::CeMatchRulePolicy, type: :model do
  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
  end

  let(:data_source) { create(:hmis_data_source) }
  let(:other_data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  describe 'Global#can_create?' do
    let(:policy) { user.policy_for(Hmis::Ce::Match::Rule, policy_type: :ce_match_rule) }

    it 'returns false without can_administrate_coordinated_entry' do
      expect(policy.can_create?).to be false
    end

    context 'when user has can_administrate_coordinated_entry' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_administrate_coordinated_entry]) }

      it 'returns true' do
        expect(policy.can_create?).to be true
      end
    end
  end

  describe 'Instance permissions' do
    let(:rule) { create(:hmis_ce_eligibility_requirement, owner: data_source) }
    let(:policy) { user.policy_for(rule, policy_type: :ce_match_rule) }

    it 'returns false without can_administrate_coordinated_entry' do
      expect(policy.can_create?).to be false
      expect(policy.can_update?).to be false
      expect(policy.can_delete?).to be false
    end

    context 'when user has can_administrate_coordinated_entry' do
      let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_administrate_coordinated_entry]) }

      it 'returns true for a rule in the current data source' do
        expect(policy.can_create?).to be true
        expect(policy.can_update?).to be true
        expect(policy.can_delete?).to be true
      end

      context 'when the rule owner is in another data source' do
        let(:rule) { create(:hmis_ce_eligibility_requirement, owner: other_data_source) }

        it 'returns false' do
          expect(policy.can_create?).to be false
          expect(policy.can_update?).to be false
          expect(policy.can_delete?).to be false
        end
      end
    end
  end
end
