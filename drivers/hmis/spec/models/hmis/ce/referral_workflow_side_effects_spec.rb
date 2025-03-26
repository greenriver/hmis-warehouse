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

  let!(:provider_acceptance_task) do # Modify task set up in 'ce spec helper' to have a side effect that creates an enrollment
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

  let!(:coc1) { create :hmis_hud_project_coc, data_source: ds1, project: project, coc_code: 'CO-500' }

  before do
    engine.start_workflow!(user: hmis_user)
    client_acceptance = engine.active_steps.sole
    engine.start_step!(client_acceptance, user: hmis_user)
    engine.complete_step!(client_acceptance, user: hmis_user, submitted_values: {})
  end

  describe 'workflow with side effect that creates an enrollment' do
    it 'creates an enrollment and associates it with the referral' do
      expect do
        current_step = engine.active_steps.sole
        engine.complete_step!(current_step, user: hmis_user, submitted_values: {})
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(1).
        and change(referral, :target_household).from(nil)

      enrollment = referral.target_household.enrollments.sole
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
        expect(referral.target_household.any_wip?).to be_falsey
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

        enrollment = referral.target_household.enrollments.sole
        expect(enrollment.enrollment_coc).to eq(coc2.coc_code)
      end
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
        current_step = engine.active_steps.sole
        engine.complete_step!(current_step, user: hmis_user, submitted_values: { 'move_in_date': move_in_date })
        referral.reload
      end.to change(Hmis::Hud::Enrollment, :count).by(1).
        and change(referral, :target_household).from(nil)

      enrollment = referral.target_household.enrollments.sole
      expect(enrollment.move_in_date).to eq(move_in_date)
    end

    context 'if enrollment does not exist yet' do
      let!(:provider_acceptance_task) do
        create(
          :hmis_workflow_definition_task,
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

      it 'raises an exception, indicating a workflow configuration issue' do
        expect do
          current_step = engine.active_steps.sole
          engine.complete_step!(current_step, user: hmis_user, submitted_values: { 'move_in_date': 2.weeks.ago.to_date })
          referral.reload
        end.to raise_error(RuntimeError, /does not have a target household yet/).
          and not_change(Hmis::Hud::Enrollment, :count)
      end
    end
  end
end
