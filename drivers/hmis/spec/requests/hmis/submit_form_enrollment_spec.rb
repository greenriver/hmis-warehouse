# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative '../../support/shared_examples/submit_form'

RSpec.describe 'SubmitForm for Enrollment', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let(:today) { Date.current }
  let(:yesterday) { today - 1.day }
  let(:two_weeks_ago) { today - 2.weeks }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: two_weeks_ago.strftime('%Y-%m-%d') }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }

  let(:definition) { Hmis::Form::Definition.find_by(role: :ENROLLMENT) }
  let(:hud_values) do
    {
      'entryDate' => yesterday.strftime('%Y-%m-%d'),
      'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
      'enrollmentCoc' => 'XX-500',
    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      project_id: p1.id,
      client_id: c2.id,
      confirmed: false,
    }
  end

  shared_examples 'returns validation error' do |**expect_validation_error_args|
    it 'returns validation error' do
      expect do
        expect_validation_error(input, **expect_validation_error_args)
      end.not_to change(Hmis::Hud::Enrollment, :count)
    end
  end

  it_behaves_like 'submit form creates form processor'
  it_behaves_like 'submit form marks enrollment for re-processing' do
    let(:enrollment) { e1 }
    let(:input) { super().merge(record_id: e1.id) }
  end
  it_behaves_like 'submit form fails when required field is missing'
  it_behaves_like 'submit form fails when form definition is draft'
  it_behaves_like 'submit form updates user correctly'

  describe 'saving a new enrollment' do
    it 'saves the new enrollment as WIP' do
      record, = submit_form(input)
      enrollment = Hmis::Hud::Enrollment.find(record['id'])
      expect(enrollment.project).to eq(p1)
      expect(enrollment.client).to eq(c2)
      expect(enrollment.relationship_to_hoh).to eq(1)
      expect(enrollment.enrollment_coc).to eq('XX-500')
      expect(enrollment.in_progress?).to eq(true)
    end

    context 'if adding second HoH to existing household' do
      let(:hud_values) { super().merge(householdId: e1.household_id).stringify_keys }
      it_behaves_like 'returns validation error', fullMessage: Hmis::Hud::Validators::EnrollmentValidator.one_hoh_full_message
    end

    context 'if creating household without HoH' do
      let(:hud_values) { super().merge(relationshipToHoH: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2)).stringify_keys }
      it_behaves_like 'returns validation error', fullMessage: Hmis::Hud::Validators::EnrollmentValidator.first_member_hoh_full_message
    end

    context 'if client already has an open enrollment in the household' do
      let!(:e2) { create(:hmis_hud_enrollment, client: c2, data_source: ds1, project: p1, entry_date: two_weeks_ago.strftime('%Y-%m-%d'), household_id: e1.household_id) }
      let(:hud_values) { super().merge(householdId: e1.household_id, relationshipToHoH: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2)).stringify_keys }
      it_behaves_like 'returns validation error',
                      fullMessage: Hmis::Hud::Validators::EnrollmentValidator.duplicate_member_full_message,
                      exact: false
    end

    context 'if client has a closed enrollment in the household' do
      let!(:exited_e2) { create(:hmis_hud_enrollment, client: c2, data_source: ds1, project: p1, entry_date: '2020-01-01', exit_date: '2020-01-01', household_id: e1.household_id) }
      let(:hud_values) { super().merge(householdId: e1.household_id, relationshipToHoH: Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2)).stringify_keys }

      it 'does not error and saves the enrollment' do
        record, = submit_form(input)
        enrollment = Hmis::Hud::Enrollment.find(record['id'])
        expect(enrollment.project).to eq(p1)
        expect(enrollment.client).to eq(c2)
        expect(enrollment.relationship_to_hoh).to eq(2)
        expect(record['householdSize']).to eq(2) # household size is 2 even though it contains 3 enrollments
      end
    end

    context 'if client is already enrolled' do
      let(:input) { super().merge(client_id: c1.id) }
      it 'returns validation error' do
        expect do
          expect_validation_error(
            input,
            fullMessage: Hmis::Hud::Validators::EnrollmentValidator.already_enrolled_full_message,
            data: { conflictingEnrollmentId: e1.id.to_s }.stringify_keys,
          )
        end.not_to change(Hmis::Hud::Enrollment, :count)
      end

      context 'and entry date is BEFORE the existing enrollment entry date' do
        let(:hud_values) { super().merge(entryDate: (e1.entry_date - 5.days).strftime('%Y-%m-%d')).stringify_keys }
        let(:input) { super().merge(client_id: c1.id, confirmed: false) }

        it 'returns validation error' do
          expect do
            expect_validation_error(
              input,
              severity: 'warning',
              fullMessage: Hmis::Hud::Validators::EnrollmentValidator.already_enrolled_full_message,
              data: { conflictingEnrollmentId: e1.id.to_s }.stringify_keys,
            )
          end.not_to change(Hmis::Hud::Enrollment, :count)
        end
      end
    end

    context 'if entry date is in the future' do
      let(:hud_values) { super().merge(entryDate: (today + 1.day).strftime('%Y-%m-%d')).stringify_keys }
      it_behaves_like 'returns validation error', message: Hmis::Hud::Validators::EnrollmentValidator.future_message
    end

    context 'if project has closed' do
      before(:each) { p1.update!(operating_end_date: today - 2.days) }
      it 'returns validation error' do
        expect do
          expect_validation_error(
            input,
            message: Hmis::Hud::Validators::BaseValidator.after_project_end_message(p1.operating_end_date),
          )
        end.not_to change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'if project has not started' do
      before(:each) { p1.update!(operating_start_date: today + 1.day) }
      it 'returns validation error' do
        expect do
          expect_validation_error(
            input,
            message: Hmis::Hud::Validators::BaseValidator.before_project_start_message(p1.operating_start_date),
          )
        end.not_to change(Hmis::Hud::Enrollment, :count)
      end
    end

    context 'when user lacks can_edit_enrollments permission' do
      before { remove_permissions(access_control, :can_edit_enrollments) }

      it 'returns access denied' do
        expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
      end
    end
  end

  describe 'updating an existing enrollment' do
    let(:wip_e1) { create :hmis_hud_wip_enrollment, data_source: ds1 }
    let(:input) { super().merge(record_id: e1.id) }

    it 'updates the enrollment' do
      expect do
        submit_form(input)
        e1.reload
      end.to change(e1, :entry_date).to(yesterday)
    end

    it 'does not change WIP status (WIP enrollment)' do
      submit_form(input.merge(record_id: wip_e1.id))
      wip_e1.reload
      expect(wip_e1.in_progress?).to eq(true)
    end

    it 'does not change WIP status (non-WIP enrollment)' do
      submit_form(input)
      e1.reload
      expect(e1.in_progress?).to eq(false)
    end

    it 'does not create a second FormProcessor on re-submission' do
      expect { submit_form(input) }.to change(Hmis::Form::FormProcessor, :count).by(1)
      expect { submit_form(input) }.not_to change(Hmis::Form::FormProcessor, :count)
    end

    context 'when updating enrollment entry date conflicts with an existing enrollment' do
      let(:e1) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1, entry_date: 5.days.ago }
      let(:e2) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1, entry_date: 20.days.ago, exit_date: 10.days.ago }

      let(:hud_values) { super().merge(entryDate: 15.days.ago.strftime('%Y-%m-%d')).stringify_keys }
      let(:input) { super().merge(record_id: e1.id) }

      it 'should warn' do
        expect_validation_error(
          input,
          severity: 'warning',
          fullMessage: Hmis::Hud::Validators::EnrollmentValidator.already_enrolled_full_message,
          data: { conflictingEnrollmentId: e2.id.to_s }.stringify_keys,
        )
      end
    end
  end

  describe 'SubmitForm for Enrollment on project with ProjectAutoEnterConfig' do
    let!(:aec) { create :hmis_project_auto_enter_config, project: p1 }

    it 'should save new enrollment without WIP status' do
      record, = submit_form(input)

      enrollment = Hmis::Hud::Enrollment.find_by(id: record['id'])
      expect(enrollment).to be_present
      expect(enrollment.in_progress?).to eq(false)
      expect(enrollment.intake_assessment).to be_present
      expect(enrollment.intake_assessment.assessment_date).to eq(enrollment.entry_date)
      expect(enrollment.intake_assessment.wip).to eq(false)
      expect(enrollment.intake_assessment.form_processor).to be_present
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
