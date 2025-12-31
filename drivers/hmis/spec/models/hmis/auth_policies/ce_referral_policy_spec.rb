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
  let(:swimlane) { create :hmis_workflow_definition_swimlane, template: workflow_template }
  let(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: workflow_template) }
  let(:unit) { create(:hmis_unit, unit_group: unit_group, project: project) }
  let(:opportunity) { create :hmis_ce_opportunity, unit: unit }
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
  let(:policy) { user.policy_for(referral, policy_type: :ce_referral) }
  let(:global_policy) { user.policy_for(Hmis::Ce::Referral, policy_type: :ce_referral) }

  describe '#can_index?' do
    it 'returns true if user has both view and perform permissions' do
      create_access_control(user, project, with_permission: [:can_view_referrals, :can_perform_any_referral_tasks])
      expect(global_policy.can_index?).to be true
    end

    it 'returns false if user only has view permission' do
      create_access_control(user, project, with_permission: [:can_view_referrals])
      expect(global_policy.can_index?).to be false
    end

    it 'returns false if user only has perform permission' do
      create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
      expect(global_policy.can_index?).to be false
    end

    it 'returns false if user has no permissions' do
      expect(global_policy.can_index?).to be false
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
        create(:hmis_workflow_definition_user_task, template: workflow_template, name: 'task', swimlane: swimlane)
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

      context 'when referral step has been completed by another user' do
        let(:other_user) { create(:hmis_user, data_source: data_source) }
        before(:each) do
          step.assignments.create!(user: other_user)
          step.start!
          step.complete!
        end

        it 'returns false' do
          expect(policy.can_view?).to be false
        end

        context 'and user is a participant on the swimlane assigned to the completed task' do
          let!(:participant) { create(:hmis_ce_referral_participant, user: user, referral: referral, swimlane: swimlane) }
          it 'returns true' do
            expect(policy.can_view?).to be true
          end
        end

        context 'and user is not a participant, but participates on this swimlane on a different referral' do
          # Set up referral to another opportunity, and assign `user` as a participant to the same swimlane that is shared for the template
          let(:unit2) { create(:hmis_unit, unit_group: unit_group, project: project) }
          let(:opportunity2) { create :hmis_ce_opportunity, unit: unit2 }
          let(:workflow_instance2) { workflow_template.instances.create! }
          let!(:referral2) do
            create(
              :hmis_ce_referral,
              opportunity: opportunity2,
              workflow_instance: workflow_instance2,
              client: client,
              referred_by: user,
              status: 'initialized',
            )
          end
          let!(:participant) { create(:hmis_ce_referral_participant, user: user, referral: referral2, swimlane: swimlane) }
          let(:step2) { create(:hmis_wfe_step, instance: workflow_instance2, node: task) }

          before(:each) do
            step2.assignments.create!(user: other_user)
            step2.start!
            step2.complete!
          end
          it 'returns false' do
            expect(policy.can_view?).to be false
          end

          it 'returns true for the other referral' do
            policy2 = user.policy_for(referral2, policy_type: :ce_referral)
            expect(policy2.can_view?).to be true
          end
        end
      end
    end

    context 'with permissions on source project' do
      let!(:source_project) { create(:hmis_hud_project, data_source: data_source) }
      let!(:source_enrollment) { create(:hmis_hud_enrollment, project: source_project, client: client, data_source: data_source) }
      let!(:referral) do
        create(
          :hmis_ce_referral,
          client: client,
          opportunity: opportunity,
          workflow_instance: workflow_instance,
          source_enrollment: source_enrollment,
        )
      end

      it 'returns true when user has can_view_outgoing_referral_details on source project' do
        create_access_control(user, source_project, with_permission: [:can_view_project, :can_view_outgoing_referral_details])
        expect(policy.can_view?).to be true
      end

      it 'returns false when user only has can_manage_outgoing_referrals (summary access only)' do
        create_access_control(user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals])
        expect(policy.can_view?).to be false
      end
    end

    it 'returns false if user has no relevant permissions' do
      expect(policy.can_view?).to be false
    end
  end

  describe '#can_perform?' do
    let(:task) { create(:hmis_workflow_definition_user_task, template: workflow_template, name: 'task') }
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

  describe '#can_view_summary?' do
    let(:source_project) { create :hmis_hud_project, data_source: data_source }
    let(:source_enrollment) { create :hmis_hud_enrollment, project: source_project, client: client, data_source: data_source }
    let(:referral) do
      create(
        :hmis_ce_referral,
        opportunity: opportunity,
        workflow_instance: workflow_instance,
        client: client,
        referred_by: user,
        status: 'initialized',
        source_enrollment: source_enrollment,
      )
    end

    context 'when user can manage outgoing referrals on source project' do
      let!(:access_control) { create_access_control(user, source_project, with_permission: [:can_manage_outgoing_referrals]) }

      it 'returns true' do
        expect(policy.can_view_summary?).to be true
      end
    end

    context 'when user can view enrollments at the target project' do
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details]) }

      it 'returns false when referral has no target enrollment' do
        expect(policy.can_view_summary?).to be false
      end

      context 'when referral has a target enrollment' do
        let(:target_enrollment) { create :hmis_hud_enrollment, project: project, client: client, data_source: data_source }
        let(:referral) do
          create(
            :hmis_ce_referral,
            opportunity: opportunity,
            workflow_instance: workflow_instance,
            client: client,
            referred_by: user,
            status: 'initialized',
            source_enrollment: source_enrollment,
            target_enrollment: target_enrollment,
          )
        end

        it 'returns true' do
          expect(policy.can_view_summary?).to be true
        end
      end
    end

    it 'returns false if user has no relevant permissions' do
      expect(policy.can_view_summary?).to be false
    end
  end

  describe '#can_create_note?' do
    let(:task) { create(:hmis_workflow_definition_user_task, template: workflow_template, name: 'task') }
    let(:step) { create(:hmis_wfe_step, instance: referral.workflow_instance, node: task) }

    context 'when step is provided' do
      context 'when user has :can_perform_any_referral_tasks permission' do
        it 'returns true' do
          create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
          expect(policy.can_create_note?(step: step)).to be true
        end
      end

      context 'when user has :can_perform_own_referral_tasks permission' do
        before { create_access_control(user, project, with_permission: [:can_perform_own_referral_tasks]) }

        it 'returns true if user is assigned to the step' do
          step.assignments.create!(user: user)
          expect(policy.can_create_note?(step: step)).to be true
        end

        it 'returns false if user is not assigned to the step' do
          expect(policy.can_create_note?(step: step)).to be false
        end
      end

      context 'when user has no relevant permissions' do
        it 'returns false' do
          expect(policy.can_create_note?(step: step)).to be false
        end
      end
    end

    context 'when step is not provided (top-level referral note)' do
      context 'when user has :can_perform_any_referral_tasks permission' do
        it 'returns true' do
          create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
          expect(policy.can_create_note?).to be true
        end
      end

      context 'when user has :can_perform_own_referral_tasks permission' do
        before { create_access_control(user, project, with_permission: [:can_perform_own_referral_tasks]) }

        it 'returns true if user is assigned to the referral' do
          step.assignments.create!(user: user)
          expect(policy.can_create_note?).to be true
        end

        it 'returns false if user is not assigned to the referral' do
          expect(policy.can_create_note?).to be false
        end
      end

      context 'when user can view referrals but not perform tasks' do
        it 'returns false' do
          create_access_control(user, project, with_permission: [:can_view_referrals])
          expect(policy.can_create_note?).to be false
        end
      end
    end
  end
end
