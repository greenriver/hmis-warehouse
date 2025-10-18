###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::Ce::ReferralEnroller, type: :model do
  include_context 'ce spec helper'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_view_enrollment_details,
        :can_edit_enrollments,
        :can_enroll_clients,
      ],
    )
  end

  let!(:coc1) { create :hmis_hud_project_coc, data_source: ds1, project: project, coc_code: 'CO-500' }

  describe 'workflow with side effect that creates an enrollment' do
    let!(:provider_acceptance_task) do
      # Modify task set up in 'ce spec helper' to have a side effect that creates an enrollment
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Provider Acceptance',
        swimlane: case_manager_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_enrollment',
          },
        ],
      )
    end

    before do
      engine.start_workflow!(user: hmis_user)
      client_acceptance = engine.active_steps.sole
      engine.start_step!(client_acceptance, user: hmis_user)
      engine.complete_step!(client_acceptance, user: hmis_user, submitted_values: {})
      # Start the next step, which will be referenced as 'current_step' in tests
      next_step = engine.active_steps.sole
      engine.start_step!(next_step, user: hmis_user)
    end

    # step that creates an enrollment
    let(:current_step) { engine.active_steps.sole }

    it 'creates an enrollment and associates it with the referral' do
      expect do
        engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(1).
        and change(referral, :target_enrollment).from(nil).
        and change(current_step, :status).to('completed')

      enrollment = referral.target_enrollment
      expect(enrollment.project).to eq(project)
      expect(enrollment.client).to eq(client)
      expect(enrollment.in_progress?).to be_truthy
      expect(enrollment.relationship_to_hoh).to eq(1)
    end

    context 'when the project has auto-enter configured' do
      let!(:auto_enter_config) { create :hmis_project_auto_enter_config, project: project }

      it 'creates an enrollment that is not WIP' do
        engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        referral.reload
        expect(referral.target_enrollment.in_progress?).to be_falsey
      end
    end

    context 'when the client already has a conflicting enrollment in the project' do
      let!(:existing_enrollment) { create :hmis_hud_enrollment, project: project, client: client }

      it 'raises an error and does not save the enrollment' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        end.to raise_error(HmisErrors::ApiError, /Client has another enrollment in this project/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when the project has no CoCs' do
      before do
        project.project_cocs.destroy_all
      end

      it 'fails to create enrollment' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        end.to raise_error(RuntimeError, /CoC Code required/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when the project has multiple CoCs' do
      let!(:coc2) { create :hmis_hud_project_coc, data_source: ds1, project: project, coc_code: 'CO-600' }

      it 'requires CoC input' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        end.to raise_error(RuntimeError, /CoC Code required/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end

      it 'succeeds when CoC input is provided' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: { Hmis::Ce::ReferralEnroller::COC_CODE_LINK_ID => 'CO-600' })
          referral.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(1)

        expect(referral.target_enrollment.enrollment_coc).to eq(coc2.coc_code)
      end
    end

    describe 'opportunity with a unit' do
      let!(:unit) { create :hmis_unit, project: project }

      before do
        opportunity.update!(unit: unit)
      end

      it 'marks the unit as occupied' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
          referral.reload
          unit.reload
        end.to change(referral, :target_enrollment).from(nil).
          and change(unit, :occupied?).from(false).to(true)

        enrollment = referral.target_enrollment
        expect(enrollment.current_unit).to eq(unit)
      end
    end

    describe 'enrolling household members from source enrollment' do
      let!(:source_project) { create :hmis_hud_project, data_source: ds1 }

      let!(:spouse) { create :hmis_hud_client, data_source: ds1 }
      let!(:child) { create :hmis_hud_client, data_source: ds1 }

      let!(:source_enrollment) { create :hmis_hud_enrollment, project: source_project, client: client, relationship_to_hoh: 1 }
      let!(:source_spouse_enrollment) { create :hmis_hud_enrollment, project: source_project, client: spouse, relationship_to_hoh: 3, household_id: source_enrollment.household_id }
      let!(:source_child_enrollment) { create :hmis_hud_enrollment, project: source_project, client: child, relationship_to_hoh: 2, household_id: source_enrollment.household_id }

      before do
        referral.update!(source_enrollment: source_enrollment)
      end

      it 'creates enrollments for all household members with correct relationships' do
        expect do
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
          referral.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(3)

        # Verify the referred client (HoH) enrollment
        referred_enrollment = referral.target_enrollment
        expect(referred_enrollment.client).to eq(client)
        expect(referred_enrollment.relationship_to_hoh).to eq(1)
        expect(referred_enrollment.project).to eq(project)

        # Verify spouse enrollment
        spouse_enrollment = Hmis::Hud::Enrollment.find_by(client: spouse, household_id: referred_enrollment.household_id)
        expect(spouse_enrollment.relationship_to_hoh).to eq(3) # Spouse relationship carried over
        expect(spouse_enrollment.project).to eq(project)

        # Verify child enrollment
        child_enrollment = Hmis::Hud::Enrollment.find_by(client: child, household_id: referred_enrollment.household_id)
        expect(child_enrollment.relationship_to_hoh).to eq(2) # Child relationship carried over
        expect(child_enrollment.project).to eq(project)

        # Verify unit occupancy
        expect(opportunity.unit.occupied?).to be_truthy
        expect(opportunity.unit.current_occupants).to contain_exactly(referred_enrollment, spouse_enrollment, child_enrollment)
      end

      context 'when referred client is no longer HoH in source household' do
        # referred client is now 3 (spouse)
        let!(:source_enrollment) { create :hmis_hud_enrollment, project: source_project, client: client, relationship_to_hoh: 3 }
        # spouse is now 1 (HoH)
        let!(:source_spouse_enrollment) { create :hmis_hud_enrollment, project: source_project, client: spouse, relationship_to_hoh: 1, household_id: source_enrollment.household_id }

        it 'creates enrollments with referred client as HoH and other relationships set to 99' do
          expect do
            engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
            referral.reload
          end.to change(Hmis::Hud::Enrollment, :count).by(3)

          # Verify the referred client becomes HoH in target household
          referred_enrollment = referral.target_enrollment
          expect(referred_enrollment.client).to eq(client)
          expect(referred_enrollment.relationship_to_hoh).to eq(1)

          # Verify original HoH enrollment has relationship set to 99
          spouse_enrollment = Hmis::Hud::Enrollment.find_by(client: spouse, household_id: referred_enrollment.household_id)
          expect(spouse_enrollment.relationship_to_hoh).to eq(99) # Data not collected

          # Verify child enrollment has relationship set to 99
          child_enrollment = Hmis::Hud::Enrollment.find_by(client: child, household_id: referred_enrollment.household_id)
          expect(child_enrollment.relationship_to_hoh).to eq(99) # Data not collected
        end
      end

      context 'when referred client has been exited from source household' do
        # referred client is exited from source household
        let!(:source_enrollment) { create :hmis_hud_enrollment, project: source_project, client: client, relationship_to_hoh: 3, exit_date: 1.week.ago }
        # spouse is not exited, so they are now the HoH
        let!(:source_spouse_enrollment) { create :hmis_hud_enrollment, project: source_project, client: spouse, relationship_to_hoh: 1, household_id: source_enrollment.household_id }

        it 'only creates enrollment for referred client' do
          expect do
            engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
            referral.reload
          end.to change(Hmis::Hud::Enrollment, :count).by(1)

          # Only the client is enrolled, not the spouse and child
          expect(Hmis::Hud::Enrollment.where(project: project).map(&:client)).to contain_exactly(client)
        end
      end

      context 'when source household includes WIP/incomplete enrollments' do
        let!(:source_spouse_enrollment) { create :hmis_hud_wip_enrollment, project: source_project, client: spouse, relationship_to_hoh: 3, household_id: source_enrollment.household_id }
        let!(:source_child_enrollment) { create :hmis_hud_wip_enrollment, project: source_project, client: child, relationship_to_hoh: 2, household_id: source_enrollment.household_id }

        it 'enrolls WIP household members as well' do
          expect do
            engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
            referral.reload
          end.to change(Hmis::Hud::Enrollment, :count).by(3)

          # All 3 are enrolled, even though the spouse and child both had WIP enrollments in the source project
          expect(Hmis::Hud::Enrollment.where(project: project).map(&:client)).to contain_exactly(client, spouse, child)
        end
      end

      context 'when source household has exited members' do
        let!(:source_spouse_enrollment) { create :hmis_hud_enrollment, exit_date: 1.week.ago, project: source_project, client: spouse, relationship_to_hoh: 3, household_id: source_enrollment.household_id }

        it 'does not enroll exited members' do
          expect do
            engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
            referral.reload
          end.to change(Hmis::Hud::Enrollment, :count).by(2)

          # Only the client and child are enrolled, since the spouse was exited
          expect(Hmis::Hud::Enrollment.where(project: project).map(&:client)).to contain_exactly(client, child)
        end
      end
    end

    describe 'workflow with side effect that creates a move-in date' do
      let(:move_in_date_link_id) { Hmis::Ce::ReferralEnroller::MOVE_IN_DATE_LINK_ID }
      let!(:move_in_date_form_def) do
        create(
          :hmis_form_definition,
          role: :CE_REFERRAL_STEP,
          definition: {
            'item': [
              {
                'type': 'GROUP',
                'link_id': 'q1',
                'item': [
                  {
                    'type': 'DATE',
                    'link_id': move_in_date_link_id,
                    'required': true,
                    'text': 'Move-in Date',
                  },
                ],
              },
            ],
          },
        )
      end

      let!(:provider_acceptance_task) do
        create(
          :hmis_workflow_definition_user_task,
          template: workflow_template,
          name: 'Provider Acceptance',
          swimlane: case_manager_swimlane,
          form_definition: move_in_date_form_def,
          trigger_config: [
            # This one has 2 side effects:
            { # 1. Create an enrollment
              event: 'complete_step',
              message: 'create_enrollment',
            },
            { # 2. Set move-in date
              event: 'complete_step',
              message: 'set_move_in_date',
            },
          ],
        )
      end

      it 'assigns the move-in date attribute on the enrollment' do
        move_in_date = 2.weeks.ago.to_date
        expect do
          current_step.form_definition = move_in_date_form_def # this is set in the mutation, not the engine complete_step!
          engine.complete_step!(current_step, user: hmis_user, submitted_values: { move_in_date_link_id => move_in_date })
          referral.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(1).
          and change(referral, :target_enrollment).from(nil).
          and change(current_step, :status).to('completed')

        expect(referral.target_enrollment.move_in_date).to eq(move_in_date)
      end

      context 'if enrollment is not created on the same task' do
        let!(:provider_acceptance_task) do
          create(
            :hmis_workflow_definition_user_task,
            template: workflow_template,
            name: 'Provider Acceptance',
            swimlane: case_manager_swimlane,
            form_definition: move_in_date_form_def,
            trigger_config: [
              {
                event: 'complete_step',
                message: 'set_move_in_date',
              },
            ],
          )
        end

        context 'if enrollment does not exist' do
          it 'raises an exception, indicating a workflow configuration issue' do
            expect do
              current_step.form_definition = move_in_date_form_def
              engine.complete_step!(current_step, user: hmis_user, submitted_values: { move_in_date_link_id => 2.weeks.ago.to_date })
              referral.reload
            end.to raise_error(RuntimeError, /does not have a target enrollment yet/).
              and not_change(Hmis::Hud::Enrollment, :count)
          end
        end

        context 'the move-in date value is not parseable' do
          it 'raises an exception' do
            expect do
              current_step.form_definition = move_in_date_form_def
              engine.complete_step!(current_step, user: hmis_user, submitted_values: { move_in_date_link_id => 'bad string' })
            end.to raise_error(RuntimeError, /Failed to parse/).
              and not_change(Hmis::Hud::Enrollment, :count)
          end
        end
      end
    end
  end

  # Demonstrating the case where enrollment is created conditionally based on a gateway,
  # and is associated with a workflow end event (not with a step that has a form).
  describe 'workflow where "acceptance" event creates an enrollment' do
    let(:accept_referral) do
      create(
        :hmis_workflow_definition_end_event,
        template: workflow_template,
        name: 'accept referral',
        trigger_config: [
          {
            event: 'end_workflow',
            message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
          },
          {
            event: 'end_workflow',
            message: 'create_enrollment',
          },
        ],
      )
    end

    let(:reject_referral) do
      create(
        :hmis_workflow_definition_end_event,
        template: workflow_template,
        name: 'reject referral',
        trigger_config: [
          {
            event: 'end_workflow',
            message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
          },
        ],
      )
    end

    let(:gateway) do
      create(
        :hmis_workflow_definition_gateway,
        template: workflow_template,
        gateway_type: 'exclusive',
        name: 'conditional gw',
      )
    end

    before do
      client_acceptance_task.outflows.destroy_all
      client_acceptance_task.connect_to!(gateway)
      gateway.connect_to!(accept_referral, condition: 'client_accepts = 1')
      gateway.connect_to!(reject_referral, condition: 'client_accepts = 0')

      engine.start_workflow!(user: hmis_user)
      engine.start_step!(engine.active_steps.sole, user: hmis_user)
    end

    it 'creates the enrollment if client accepts' do
      expect do
        engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: { 'client_accepts': 1 })
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(1).
        and change(referral, :target_enrollment).from(nil)

      enrollment = referral.target_enrollment
      expect(enrollment.project).to eq(project)
      expect(enrollment.client).to eq(client)
      expect(enrollment.in_progress?).to be_truthy
      expect(enrollment.relationship_to_hoh).to eq(1)
    end

    it 'does not create the enrollment if client does not accept' do
      expect do
        engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: { 'client_accepts': 0 })
        referral.reload
      end.to not_change(Hmis::Hud::Enrollment, :count).
        and not_change(referral, :target_enrollment).from(nil)
    end
  end

  describe 'workflow with side effect that deletes a WIP enrollment' do
    let!(:source_project) { create :hmis_hud_project, data_source: ds1 }

    let!(:spouse) { create :hmis_hud_client, data_source: ds1 }
    let!(:child) { create :hmis_hud_client, data_source: ds1 }

    let!(:source_enrollment) { create :hmis_hud_enrollment, project: source_project, client: client, relationship_to_hoh: 1 }
    let!(:source_spouse_enrollment) { create :hmis_hud_enrollment, project: source_project, client: spouse, relationship_to_hoh: 3, household_id: source_enrollment.household_id }
    let!(:source_child_enrollment) { create :hmis_hud_enrollment, project: source_project, client: child, relationship_to_hoh: 2, household_id: source_enrollment.household_id }

    let!(:referral) do
      create(
        :hmis_ce_referral,
        opportunity: opportunity,
        workflow_instance: workflow_instance,
        client: client,
        referred_by: hmis_user,
        status: 'initialized',
        source_enrollment: source_enrollment,
      )
    end

    let!(:provider_acceptance_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Provider Acceptance',
        swimlane: provider_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_enrollment',
          },
        ],
      )
    end

    let!(:confirm_success_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Confirm Success',
        swimlane: case_manager_swimlane,
      )
    end

    let!(:change_provider_outcome_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Change Provider Outcome',
        swimlane: provider_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'delete_wip_enrollment',
          },
        ],
      )
    end

    before do
      # Set up the workflow flow: client_acceptance -> provider_acceptance -> change_provider_outcome
      client_acceptance_task.outflows.destroy_all
      provider_acceptance_task.outflows.destroy_all

      client_acceptance_task.connect_to!(provider_acceptance_task)
      provider_acceptance_task.connect_to!(change_provider_outcome_task)
      provider_acceptance_task.connect_to!(confirm_success_task)
      change_provider_outcome_task.connect_to!(reject_referral)
      confirm_success_task.connect_to!(accept_referral)

      engine.start_workflow!(user: hmis_user)

      # Complete client acceptance
      first_step = engine.active_steps.sole
      engine.start_step!(first_step, user: hmis_user)
      engine.complete_step!(first_step, user: hmis_user, submitted_values: {})

      # Complete provider acceptance (creates enrollment)
      second_step = engine.active_steps.sole
      engine.start_step!(second_step, user: hmis_user)
      engine.complete_step!(second_step, user: hmis_user, submitted_values: {})
    end

    let(:change_provider_outcome_step) do
      # Start change provider outcome step (the one that will delete enrollment)
      current_step = engine.active_steps.where(node: change_provider_outcome_task).sole
      engine.start_step!(current_step, user: hmis_user)

      current_step
    end

    it 'deletes the target enrollment and household members, and clears the referral association' do
      referral.reload
      enrollment = referral.target_enrollment
      expect(enrollment).to be_present
      expect(enrollment.in_progress?).to be_truthy

      expect do
        engine.complete_step!(change_provider_outcome_step, user: hmis_user, submitted_values: {})
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(-3).
        and change(referral, :target_enrollment).from(enrollment).to(nil).
        and change(change_provider_outcome_step, :status).to('completed')

      # Verify the enrollment was deleted
      expect(enrollment.reload.date_deleted).not_to be_nil
    end

    it 'does not delete if the target enrollment is not WIP' do
      referral.reload
      enrollment = referral.target_enrollment
      expect(enrollment).to be_present
      expect(enrollment.in_progress?).to be_truthy

      enrollment.save_not_in_progress!

      expect do
        engine.complete_step!(change_provider_outcome_step, user: hmis_user, submitted_values: {})
        referral.reload
      end.to raise_error(/unable to perform delete_wip_enrollment/).
        and not_change(Hmis::Hud::Enrollment, :count).
        and not_change(referral, :target_enrollment)
    end

    context 'when referral has an enrollment with a unit assignment' do
      let!(:unit) { create :hmis_unit, project: project }
      let!(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: workflow_template, unit: unit }

      it 'deletes the enrollment and frees up the unit' do
        referral.reload
        enrollment = referral.target_enrollment
        unit.reload
        expect(enrollment).to be_present
        expect(enrollment.current_unit).to eq(unit)
        expect(unit.occupied?).to be_truthy

        expect do
          engine.complete_step!(change_provider_outcome_step, user: hmis_user, submitted_values: {})
          referral.reload
          unit.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(-3).
          and change(referral, :target_enrollment).from(enrollment).to(nil).
          and change(unit, :occupied?).from(true).to(false)
      end
    end
  end
end
