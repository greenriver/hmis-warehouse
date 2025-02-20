###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::AutoExitJob, type: :model do
  # Probably other specs aren't cleaning up:
  before(:all) { cleanup_test_environment }

  let!(:ds1) { create(:hmis_data_source) }
  let!(:u1) { create :hmis_hud_user, data_source: ds1, user_email: 'test@example.com' }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }

  describe 'for night-by-night shelter' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 1 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:aec) { create :hmis_project_auto_exit_config, length_of_absence_days: 30, project: p1 }

    it 'should exit correctly based on most recent bed night' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      e2 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 200
      s2 = create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e2, user: u1, record_type: 200, date_provided: Date.current - 31.days

      # It should ignore this CLS even though it was recent
      create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e2, user: u1, information_date: Date.current - 5.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e2)
      expect(Hmis::Hud::Enrollment.exited).not_to include(e1)
      expect(e2.exit).to have_attributes(auto_exited: be_present, exit_date: s2.date_provided + 1.day, destination: 30)
      expect(e2.exit_assessment&.assessment_date).to eq(s2.date_provided + 1.day)
      expect(e2.exit_assessment&.data_collection_stage).to eq(3)
    end

    it 'should exit based on entry date +1 if client had no bed nights' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: e1.entry_date + 1.day, destination: 30)
      expect(e1.exit_assessment).to be_present
    end

    it 'should ignore bed night that is missing DateProvided' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: Date.current - 2.months
      create :hmis_hud_service, :skip_validate, data_source: ds1, client: c1, enrollment: e1, record_type: 200, date_provided: nil

      Hmis::AutoExitJob.perform_now
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: e1.entry_date + 1.day, destination: 30)
    end

    it 'should not fail if enrollment has contact date before entry (regression #7178)' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      # most recent bed night is before enrollment entry, which is a DQ issue, but should not cause the AutoExitJob to break.
      # It should auto-exit the enrollment with the entry date as its exit date.
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 200, date_provided: Date.current - 3.months

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: e1.entry_date + 1.day, destination: 30)
      expect(e1.exit_assessment&.assessment_date).to eq(e1.entry_date + 1.day)
      expect(e1.exit_assessment&.data_collection_stage).to eq(3)
    end

    context 'with a multi member household' do
      let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
      let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
      let!(:household_id) { Hmis::Hud::Base.generate_uuid }
      let!(:hoh_e) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, household_id: household_id, entry_date: Date.current - 2.months }
      let!(:hhm_e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, household_id: household_id, relationship_to_hoh: 2, entry_date: Date.current - 2.months }
      let!(:hhm_e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, household_id: household_id, relationship_to_hoh: 2, entry_date: Date.current - 2.months }

      def expect_all_active
        hoh_e.household_members.each do |member|
          expect(member.exit).to be_nil
        end
      end

      context 'when a household member has a recent contact' do
        let!(:hhm_service) { create :hmis_hud_service, data_source: ds1, client: c2, enrollment: hhm_e1, user: u1, record_type: 200, date_provided: Date.current - 2.days }

        it 'should not exit the HoH or other members' do
          Hmis::AutoExitJob.perform_now
          expect_all_active
        end
      end

      context 'when there is a WIP enrollment in the household' do
        let!(:hhm_e1) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, household_id: household_id, relationship_to_hoh: 2, entry_date: Date.current - 2.months }

        it 'should not exit the HoH or any household member' do
          Hmis::AutoExitJob.perform_now
          expect_all_active
        end
      end

      context 'when the HoH has a recent contact' do
        let!(:hoh_service) { create :hmis_hud_service, data_source: ds1, client: c2, enrollment: hoh_e, user: u1, record_type: 200, date_provided: Date.current - 2.days }

        it 'should not exit the HoH or any household member' do
          Hmis::AutoExitJob.perform_now
          expect_all_active
        end
      end

      context 'when the HoH has an incomplete enrollment' do
        let!(:hoh_e) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c2, household_id: household_id, entry_date: Date.current - 2.months }

        it 'should not exit any member if another member has an incomplete enrollment' do
          Hmis::AutoExitJob.perform_now
          expect_all_active
        end
      end

      context 'when one household member is already exited' do
        let!(:hhm_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: hhm_e1, client: c2, exit_date: Date.current - 1.week }

        it 'should only exit the clients that dont already have exit records' do
          expected_exit_date = hoh_e.entry_date + 1.day
          expect do
            Hmis::AutoExitJob.perform_now
            [hoh_e, hhm_e1, hhm_e2].each(&:reload)
          end.to change { hoh_e.exit_date }.from(nil).to(expected_exit_date).
            and change { hhm_e2.exit_date }.from(nil).to(expected_exit_date).
            and(not_change { hhm_e1.exit_date }).
            and(not_change { Hmis::Hud::Exit.where(enrollment_id: hhm_e1.enrollment_id, data_source_id: hhm_e1.data_source_id).count })
        end
      end
    end
  end

  describe 'for other project types (not ES NBN)' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 6 }
    let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:aec) { create :hmis_project_auto_exit_config, length_of_absence_days: 30, project: p1 }

    it 'should exit correctly for a service' do
      contact_date = Date.current - 31.days

      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: contact_date - 1.day
      s2 = create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: contact_date

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: s2.date_provided, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: s2.date_provided, data_collection_stage: 3))
      expect(e1.exit_assessment.form_processor.exit).to eq(e1.exit)
    end

    it 'should exit correctly for a custom service' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      cs1 = create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.current - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cs1.date_provided, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: cs1.date_provided, data_collection_stage: 3))
    end

    it 'should exit correctly for a current living situation' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      cls1 = create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e1, user: u1, information_date: Date.current - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cls1.information_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(have_attributes(assessment_date: cls1.information_date, data_collection_stage: 3))
    end

    it 'should exit correctly for an assessment' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      ca1 = create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1, assessment_date: Date.current - 31.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: ca1.assessment_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(ca1, have_attributes(assessment_date: ca1.assessment_date, data_collection_stage: 3))
    end

    it 'should pick the latest exit date for all entities considered as contacts' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
      create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1, record_type: 141, type_provided: 1, date_provided: Date.current - 33.days
      create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.current - 32.days
      cls1 = create :hmis_current_living_situation, data_source: ds1, client: c1, enrollment: e1, user: u1, information_date: Date.current - 31.days
      ca1 = create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1, assessment_date: Date.current - 34.days

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: cls1.information_date, destination: 30)
      expect(e1.custom_assessments).to contain_exactly(ca1, have_attributes(assessment_date: cls1.information_date, data_collection_stage: 3))
    end

    it 'should exit based on entry date if client had no other contacts' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months

      Hmis::AutoExitJob.perform_now

      expect(Hmis::Hud::Enrollment.exited).to include(e1)
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: e1.entry_date, destination: 30)
      expect(e1.exit_assessment).to be_present
    end

    it 'should ignore Service that is missing DateProvided' do
      e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: Date.current - 2.months
      create :hmis_hud_service, :skip_validate, data_source: ds1, client: c1, enrollment: e1, record_type: 141, type_provided: 1, date_provided: nil

      Hmis::AutoExitJob.perform_now
      expect(e1.exit).to have_attributes(auto_exited: be_present, exit_date: e1.entry_date, destination: 30)
    end
  end

  it 'should throw error if length_of_absence_days is less than 30' do
    p1 = create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 6
    c1 = create :hmis_hud_client, data_source: ds1, user: u1

    # We want to set the length_of_absence_days to 29 to test logic in the job, but there is an AR validation on this too, so set it without validating
    aec = create :hmis_project_auto_exit_config, length_of_absence_days: 30, project: p1
    aec.length_of_absence_days = 29
    aec.save!(validate: false)

    e1 = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: Date.current - 2.months
    create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, date_provided: Date.current - 31.days

    expect { Hmis::AutoExitJob.perform_now }.to raise_error('Auto-exit config unusually low: 29')

    expect(e1.exit).to be_nil
  end

  describe 'for enrollment with no contacts' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }
    let!(:aec) { create :hmis_project_auto_exit_config, length_of_absence_days: 30, organization: o1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 2.months.ago }

    context 'residential project type' do
      # PH project (9)
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 9 }
      it 'uses EntryDate+1 as ExitDate' do
        expect do
          Hmis::AutoExitJob.perform_now
        end.to change { e1.reload.exit&.exit_date }.from(nil).to(e1.entry_date + 1.day)
      end
    end

    context 'non-residential project type' do
      # Services Only project (6)
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 6 }
      it 'uses EntryDate as ExitDate' do
        expect do
          Hmis::AutoExitJob.perform_now
        end.to change { e1.reload.exit&.exit_date }.from(nil).to(e1.entry_date)
      end
    end
  end

  describe 'can run for specific projects or data sources' do
    # ds1 with 1 project set up to auto-exit, and 1 eligible enrollment
    let!(:ds1) { create(:hmis_data_source) }
    let!(:p1) { create :hmis_hud_project, data_source: ds1 }
    let!(:aec) { create :hmis_project_auto_exit_config, length_of_absence_days: 30, project: p1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.months.ago }

    let!(:ds2) { create(:hmis_data_source) }
    let!(:p2) { create :hmis_hud_project, data_source: ds2 }
    let!(:aec2) { create :hmis_project_auto_exit_config, length_of_absence_days: 30, project: p2 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds2, project: p2, entry_date: 2.months.ago }

    it 'should only auto-exit enrollments for the specified data source' do
      expect do
        Hmis::AutoExitJob.perform_now(data_source_id: ds1.id)
      end.to change { e1.reload.exit&.exit_date }.from(nil).to(be_present).
        and change(Hmis::Hud::Exit, :count).by(1)

      expect do
        Hmis::AutoExitJob.perform_now(data_source_id: ds2.id)
      end.to change { e2.reload.exit&.exit_date }.from(nil).to(be_present).
        and change(Hmis::Hud::Exit, :count).by(1)
    end

    it 'should only auto-exit enrollments for the specified project' do
      expect do
        Hmis::AutoExitJob.perform_now(project_ids: [p1.id])
      end.to change { e1.reload.exit&.exit_date }.from(nil).to(be_present).
        and change(Hmis::Hud::Exit, :count).by(1)

      expect do
        Hmis::AutoExitJob.perform_now(project_ids: [p2.id])
      end.to change { e2.reload.exit&.exit_date }.from(nil).to(be_present).
        and change(Hmis::Hud::Exit, :count).by(1)
    end
  end
end
