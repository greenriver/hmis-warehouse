# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::CeReferralPolicy, type: :model do
  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:client) { create :hmis_hud_client_complete, data_source: data_source }
  let(:project) { create :hmis_hud_project, data_source: data_source }
  let(:workflow_template) { create(:hmis_workflow_definition_template, data_source: data_source) }
  let(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: workflow_template }
  let(:workflow_instance) { workflow_template.instances.create! }
  let(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      workflow_instance: workflow_instance,
      client: client,
      referred_by: user,
      status: 'initialized',
    )
  end
  let(:policy) { user.policy_for(referral, policy: :ce_referral) }

  describe '#can_index?' do
    it 'returns true if user has both view and perform permissions' do
      create_access_control(user, project, with_permission: [:can_view_referrals, :can_perform_any_referral_tasks])
      expect(policy.can_index?).to be true
    end

    it 'returns false if user only has view permission' do
      create_access_control(user, project, with_permission: [:can_view_referrals])
      expect(policy.can_index?).to be false
    end

    it 'returns false if user only has perform permission' do
      create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
      expect(policy.can_index?).to be false
    end

    it 'returns false if user has no permissions' do
      expect(policy.can_index?).to be false
    end
  end

  describe '#can_view?' do
    context 'with can_view_referrals permission' do
      it 'returns true if user also has can_view_project' do
        create_access_control(user, project, with_permission: [:can_view_referrals, :can_view_project])
        expect(policy.can_view?).to be true
      end

      it 'returns false if user does not have can_view_project' do
        create_access_control(user, project, with_permission: [:can_view_referrals])
        expect(policy.can_view?).to be false
      end
    end

    context 'with can_view_own_referrals permission' do
      let(:task) do
        create(:hmis_workflow_definition_task, template: workflow_template, name: 'task')
      end
      let(:step) do
        create(:hmis_wfe_step, instance: referral.workflow_instance, node: task)
      end
      before do
        create_access_control(user, project, with_permission: [:can_view_own_referrals])
      end

      it 'returns true if user is assigned to the referral' do
        step.assignments.create!(user: user)
        expect(policy.can_view?).to be true
      end

      it 'returns false if user is not assigned to the referral' do
        expect(policy.can_view?).to be false
      end
    end

    it 'returns false if user has no relevant permissions' do
      expect(policy.can_view?).to be false
    end
  end

  describe '#can_perform?' do
    let(:task) { create(:hmis_workflow_definition_task, template: workflow_template, name: 'task') }
    let(:step) { create(:hmis_wfe_step, instance: referral.workflow_instance, node: task) }

    context 'when user has :can_perform_any_referral_tasks permission' do
      it 'returns true' do
        create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
        expect(policy.can_perform?(step: step)).to be true
      end
    end

    context 'when user has :can_perform_own_referral_tasks permission' do
      before { create_access_control(user, project, with_permission: [:can_perform_own_referral_tasks]) }

      it 'returns true if user is assigned to the step' do
        step.assignments.create!(user: user)
        expect(policy.can_perform?(step: step)).to be true
      end

      it 'returns false if user is not assigned to the step' do
        expect(policy.can_perform?(step: step)).to be false
      end
    end

    context 'when user has no relevant permissions' do
      it 'returns false' do
        expect(policy.can_perform?(step: step)).to be false
      end
    end
  end
end
