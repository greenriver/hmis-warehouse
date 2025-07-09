# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::CeOpportunityPolicy, type: :model do
  before { allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true) }

  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:workflow_template) { create(:hmis_workflow_definition_template, data_source: data_source) }
  let(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: workflow_template }
  let(:policy) { user.policy_for(opportunity, policy: :ce_opportunity) }

  describe '#can_create_referral?' do
    let(:client) { create(:hmis_hud_client_complete, data_source: data_source) }

    context 'when user has :can_start_referrals permission' do
      before { create_access_control(user, project, with_permission: [:can_start_referrals]) }

      it 'returns true if client is in the same data source' do
        expect(policy.can_create_referral?(client: client)).to be true
      end

      it 'returns false if client is in a different data source' do
        other_data_source = create(:hmis_data_source)
        other_client = create(:hmis_hud_client_complete, data_source: other_data_source)
        expect(policy.can_create_referral?(client: other_client)).to be false
      end
    end

    context 'when user does not have :can_start_referrals permission' do
      it 'returns false' do
        expect(policy.can_create_referral?(client: client)).to be false
      end
    end
  end

  describe '#can_view_candidates?' do
    context 'when user has :can_view_prioritized_client_lists permission' do
      it 'returns true' do
        create_access_control(user, project, with_permission: [:can_view_prioritized_client_lists])
        expect(policy.can_view_candidates?).to be true
      end
    end

    context 'when user does not have :can_view_prioritized_client_lists permission' do
      it 'returns false' do
        expect(policy.can_view_candidates?).to be false
      end
    end
  end
end
