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
        :hmis_workflow_definition_task,
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
    end

    it 'creates an enrollment and associates it with the referral' do
      expect do
        current_step = engine.active_steps.sole
        engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(1).
        and change(referral, :target_enrollment).from(nil)

      enrollment = referral.target_enrollment
      expect(enrollment.project).to eq(project)
      expect(enrollment.client).to eq(client)
      expect(enrollment.in_progress?).to be_truthy
      expect(enrollment.relationship_to_hoh).to eq(1)
    end

    context 'when the project has auto-enter configured' do
      let!(:auto_enter_config) { create :hmis_project_auto_enter_config, project: project }

      it 'creates an enrollment that is not WIP' do
        engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: {})
        referral.reload
        expect(referral.target_enrollment.in_progress?).to be_falsey
      end
    end

    context 'when the client already has a conflicting enrollment in the project' do
      let!(:existing_enrollment) { create :hmis_hud_enrollment, project: project, client: client }

      it 'raises an error and does not save the enrollment' do
        expect do
          engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: {})
        end.to raise_error(HmisErrors::ApiError, /Client has another enrollment in this project/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when the user does not have permission to enroll clients' do
      let!(:ds_access_control) do
        # User lacks ability to enroll clients or edit enrollments
        create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
      end
      # User CAN enroll clients at other projects
      let!(:other_project) { create :hmis_hud_project, data_source: ds1 }
      let!(:other_access_control) { create_access_control(hmis_user, other_project, with_permission: [:can_enroll_clients]) }

      it 'raises an error and does not save the enrollment' do
        expect do
          engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: {})
        end.to raise_error(RuntimeError, /access denied/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when the project has no CoCs' do
      before do
        project.project_cocs.destroy_all
      end

      it 'fails to create enrollment' do
        expect do
          engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: {})
        end.to raise_error(RuntimeError, /CoC Code required/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when the project has multiple CoCs' do
      let!(:coc2) { create :hmis_hud_project_coc, data_source: ds1, project: project, coc_code: 'CO-600' }

      it 'requires CoC input' do
        expect do
          engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: {})
        end.to raise_error(RuntimeError, /CoC Code required/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end

      it 'succeeds when CoC input is provided' do
        expect do
          engine.complete_step!(engine.active_steps.sole, user: hmis_user, submitted_values: { 'coc_code': 'CO-600' })
          referral.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(1)

        expect(referral.target_enrollment.enrollment_coc).to eq(coc2.coc_code)
      end
    end

    describe 'workflow with side effect that creates a move-in date' do
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
                    'link_id': 'move_in_date',
                    'required': true,
                    'text': 'Move-in Date',
                    'mapping': { 'field_name': 'moveInDate', 'record_type': 'ENROLLMENT' },
                  },
                ],
              },
            ],
          },
        )
      end

      let!(:provider_acceptance_task) do
        create(
          :hmis_workflow_definition_task,
          template: workflow_template,
          name: 'Provider Acceptance',
          swimlane: case_manager_swimlane,
          form_definition_identifier: move_in_date_form_def.identifier,
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
          current_step = engine.active_steps.sole
          engine.complete_step!(current_step, user: hmis_user, submitted_values: { 'move_in_date': move_in_date })
          referral.reload
        end.to change(Hmis::Hud::Enrollment, :count).by(1).
          and change(referral, :target_enrollment).from(nil)

        expect(referral.target_enrollment.move_in_date).to eq(move_in_date)
      end

      context 'if enrollment is not created on the same task' do
        let!(:provider_acceptance_task) do
          create(
            :hmis_workflow_definition_task,
            template: workflow_template,
            name: 'Provider Acceptance',
            swimlane: case_manager_swimlane,
            form_definition_identifier: move_in_date_form_def.identifier,
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
              current_step = engine.active_steps.sole
              engine.complete_step!(current_step, user: hmis_user, submitted_values: { 'move_in_date': 2.weeks.ago.to_date })
              referral.reload
            end.to raise_error(RuntimeError, /does not have a target enrollment yet/).
              and not_change(Hmis::Hud::Enrollment, :count)
          end
        end

        context 'if the enrollment already has a move-in date' do
          let!(:move_in_date) { 2.days.ago }
          let!(:target_enrollment) do
            create(
              :hmis_hud_enrollment,
              project: project,
              client: referral.client,
              entry_date: 2.weeks.ago,
              move_in_date: move_in_date,
            )
          end

          before do
            referral.update!(target_enrollment: target_enrollment)
          end

          it 'does not overwrite the move-in date if the input is not parseable' do
            expect do
              current_step = engine.active_steps.sole
              engine.complete_step!(current_step, user: hmis_user, submitted_values: { 'move_in_date': 'bad string' })
              target_enrollment.reload
            end.to not_change(Hmis::Hud::Enrollment, :count).
              and not_change(target_enrollment, :move_in_date)
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
            message: 'accept_referral',
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
            message: 'reject_referral',
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
end
