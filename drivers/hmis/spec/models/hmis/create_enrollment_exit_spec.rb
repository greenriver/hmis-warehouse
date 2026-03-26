# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::CreateEnrollmentExit, type: :model do
  let!(:ds1) { create(:hmis_data_source) }
  let!(:u1) { create :hmis_hud_user, data_source: ds1, user_email: 'test@example.com' }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 6 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:entry_date) { Date.current - 2.months }
  let(:exit_date) { Date.current - 1.day }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: entry_date }

  let(:system_hud_user) { Hmis::Hud::User.system_user(data_source_id: ds1.id) }

  def perform_exit(enrollment:, **kwargs)
    defaults = { enrollment_id: enrollment.id, exit_date: exit_date }
    described_class.call(**defaults.merge(kwargs))
  end

  def expect_exit_assessment_shape(enrollment:, exit_date:, hud_user:)
    enrollment.reload
    exit_assessment = enrollment.exit_assessment
    expect(exit_assessment).to be_present
    expect(exit_assessment.assessment_date).to eq(exit_date)
    expect(exit_assessment.data_collection_stage).to eq(3)
    expect(exit_assessment.personal_id).to eq(enrollment.personal_id)
    expect(exit_assessment.enrollment_id).to eq(enrollment.enrollment_id)
    expect(exit_assessment.data_source_id).to eq(enrollment.data_source_id)
    expect(exit_assessment.wip).to eq(false)
    expect(exit_assessment.form_processor).to be_present
    expect(exit_assessment.form_processor.exit).to eq(enrollment.exit)
    expect(exit_assessment.created_by_hud_user).to eq(hud_user)
    expect(exit_assessment.updated_by_hud_user).to eq(hud_user)
    expect(exit_assessment.user_id).to eq(hud_user.user_id)
  end

  it 'creates exit and exit assessment with default options' do
    expect do
      perform_exit(enrollment: e1)
    end.to change(Hmis::Hud::Exit, :count).by(1).
      and change(Hmis::Hud::CustomAssessment, :count).by(1).
      and change(Hmis::Form::FormProcessor, :count).by(1)

    e1.reload
    expect(e1.exit).to have_attributes(
      exit_date: exit_date,
      destination: HudHelper.util.destination_no_exit_interview_completed,
      auto_exited: nil,
    )
    expect_exit_assessment_shape(enrollment: e1, exit_date: exit_date, hud_user: system_hud_user)
  end

  context 'with exit_destination' do
    it 'uses the provided HUD destination code' do
      custom_destination = 329

      perform_exit(enrollment: e1, exit_destination: custom_destination)

      expect(e1.reload.exit.destination).to eq(custom_destination)
    end

    it 'falls back to default destination when exit_destination is blank' do
      perform_exit(enrollment: e1, exit_destination: '')

      expect(e1.reload.exit.destination).to eq(HudHelper.util.destination_no_exit_interview_completed)
    end
  end

  context 'with auto_exited timestamp' do
    it 'stores auto_exited on the Exit record' do
      ts = Time.zone.parse('2024-06-01 15:30:00')

      perform_exit(enrollment: e1, auto_exited: ts)

      expect(e1.reload.exit.auto_exited).to be_within(1.second).of(ts)
    end
  end

  context 'with acting_user_id' do
    let!(:acting_app_user) { create(:hmis_user, data_source: ds1) }
    let(:acting_hud_user) { Hmis::Hud::User.from_user(acting_app_user) }

    it 'attributes the exit assessment to that user' do
      perform_exit(enrollment: e1, acting_user_id: acting_app_user.id)

      expect_exit_assessment_shape(enrollment: e1, exit_date: exit_date, hud_user: acting_hud_user)
    end
  end

  context 'with multiple household members' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:hoh_e) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, household_id: household_id, entry_date: entry_date }
    let!(:hhm_e) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, household_id: household_id, relationship_to_hoh: 2, entry_date: entry_date }
    let!(:hhm_exited) { create :hmis_hud_enrollment, data_source: ds1, project: p1, household_id: household_id, relationship_to_hoh: 2, entry_date: entry_date }
    let!(:hhm_exited_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: hhm_exited, client: hhm_exited.client, exit_date: exit_date + 1.day }

    it 'exits all open household members when exit_household_members is true' do
      expect do
        perform_exit(enrollment: hoh_e, exit_household_members: true)
      end.to change(Hmis::Hud::Exit, :count).by(2). # Exited HoH and one HHM
        and(not_change { hhm_exited_exit.reload.exit_date }) # Already-exited HHM is not affected

      [hoh_e, hhm_e].each do |enrollment|
        expect(enrollment.reload.exit).to have_attributes(exit_date: exit_date)
        expect_exit_assessment_shape(enrollment: enrollment, exit_date: exit_date, hud_user: system_hud_user)
      end
    end

    it 'exits only the given enrollment when exit_household_members is false' do
      expect do
        perform_exit(enrollment: hoh_e, exit_household_members: false)
      end.to change(Hmis::Hud::Exit, :count).by(1)

      expect(hoh_e.reload.exit).to be_present
      expect(hhm_e.reload.exit).to be_nil
      expect_exit_assessment_shape(enrollment: hoh_e, exit_date: exit_date, hud_user: system_hud_user)
    end
  end

  context 'when a household member enrollment is WIP (incomplete)' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:hoh_e) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, household_id: household_id, entry_date: entry_date }
    let!(:wip_e) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, user: u1, household_id: household_id, relationship_to_hoh: 2, entry_date: entry_date }

    it 'raises when exit_household_members is true (cannot partially exit a household with incomplete members)' do
      expect do
        perform_exit(enrollment: hoh_e, exit_household_members: true)
      end.to raise_error(RuntimeError, 'Cannot exit incomplete enrollments').
        and(not_change(Hmis::Hud::Exit, :count))
    end
  end

  context 'when enrollment data source is not HMIS' do
    let!(:non_hmis_ds) { create(:grda_warehouse_data_source) }
    let!(:wh_enrollment) { create :hud_enrollment, data_source: non_hmis_ds, entry_date: entry_date }

    it 'raises so HMIS-only side effects are not applied to warehouse-only data' do
      expect(non_hmis_ds.hmis?).to eq(false)

      expect do
        perform_exit(enrollment: wh_enrollment)
      end.to raise_error(RuntimeError, 'CreateEnrollmentExit invoked on non-HMIS enrollments')
    end
  end

  context 'when enrollments are already exited' do
    before do
      perform_exit(enrollment: e1)
    end

    it 'returns without creating duplicate exits (idempotent)' do
      expect do
        perform_exit(enrollment: e1)
      end.not_to change(Hmis::Hud::Exit, :count)
    end
  end
end
