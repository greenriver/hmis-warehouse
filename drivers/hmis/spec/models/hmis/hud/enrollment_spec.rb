require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Enrollment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  describe 'in progress enrollments' do
    let!(:enrollment) { build(:hmis_hud_enrollment) }
    before(:each) do
      enrollment.build_wip(client: enrollment.client, date: enrollment.entry_date)
      enrollment.save_in_progress
    end

    it 'clean up dependent wip after destroy' do
      expect(enrollment.wip).to be_present

      enrollment.destroy
      enrollment.reload
      expect(enrollment.wip).not_to be_present
    end
  end

  describe 'saved enrollments' do
    let!(:enrollment) { create(:hmis_hud_enrollment) }

    before(:each) do
      create(:hmis_hud_exit, data_source: enrollment.data_source, enrollment: enrollment, client: enrollment.client)
      create(:hmis_hud_service, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_hud_event, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_income_benefit, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_disability, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_health_and_dv, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_current_living_situation, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_enrollment_coc, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_hud_assessment, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_employment_education, data_source: enrollment.data_source, enrollment: enrollment)
      create(:hmis_youth_education_status, data_source: enrollment.data_source, enrollment: enrollment)

      enrollment.save_not_in_progress
    end

    it 'preserve shared data after destroy' do
      enrollment.destroy
      enrollment.reload

      [
        :project,
        :client,
        :user,
      ].each do |assoc|
        expect(enrollment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end
    end

    it 'destroy dependent data' do
      enrollment.reload
      [
        :exit,
        :services,
        :events,
        :income_benefits,
        :disabilities,
        :health_and_dvs,
        :current_living_situations,
        :enrollment_cocs,
        :assessments,
        :employment_educations,
        :youth_education_statuses,
      ].each do |assoc|
        expect(enrollment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end

      enrollment.destroy
      enrollment.reload

      [
        :exit,
        :services,
        :events,
        :income_benefits,
        :disabilities,
        :health_and_dvs,
        :current_living_situations,
        :enrollment_cocs,
        :assessments,
        :employment_educations,
        :youth_education_statuses,
      ].each do |assoc|
        expect(enrollment.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
      end
    end
  end

  describe 'enrollments status is set correctly:' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1 }

    it 'household with two entered members' do
      e1.update(household_id: e2.household_id)
      expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ACTIVE')
      expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('ACTIVE')
    end

    describe 'entry statuses' do
      let!(:intake_assessment) { create :hmis_custom_assessment, data_source: ds1, data_collection_stage: 1 }

      before(:each) do
        # link e1 and e2
        e1.update(household_id: e2.household_id)

        # make e2 WIP
        e2.build_wip(client: e2.client, date: e2.entry_date)
        e2.save_in_progress
      end

      it 'household with one entered (e1) and one WIP with no intake assessment (e2)' do
        expect(e1.wip).to be nil
        expect(e2.wip).to be_present
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end

      it 'household with one entered (e1) and one WIP with a WIP intake assessment (e2)' do
        intake_assessment.update(enrollment: e2)
        intake_assessment.build_wip(enrollment: intake_assessment.enrollment, client: intake_assessment.enrollment.client, date: intake_assessment.assessment_date)
        intake_assessment.save_in_progress

        expect(e1.wip).to be nil
        expect(e2.wip).to be_present
        expect(e2.intake_assessment).to be_present
        expect(e2.intake_assessment.in_progress?).to eq(true)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end

      it 'household with one entered (e1) and one WIP with a submitted intake assessment (e2, bad state)' do
        intake_assessment.update(enrollment: e2)

        expect(e1.wip).to be nil
        expect(e2.wip).to be_present
        expect(e2.intake_assessment).to be_present
        expect(e2.intake_assessment.in_progress?).to eq(false)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e1)).to eq('ANY_ENTRY_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_ENTRY_INCOMPLETE')
      end
    end

    describe 'exit statuses' do
      let!(:exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e3, client: e3.client }
      let!(:exit_assessment) { create :hmis_custom_assessment, data_source: ds1, data_collection_stage: 3 }

      before(:each) do
        # make e3 exited
        exit.update(enrollment: e3)
        # link e2 and e3
        e2.update(household_id: e3.household_id)
      end

      it 'household with one exited (e3) and one unexited with no exit assessment (e2)' do
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('EXITED')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('ACTIVE')
      end

      it 'household with one exited (e3) and one unexited with a WIP exit assessment (e2)' do
        exit_assessment.update(enrollment: e2)
        exit_assessment.build_wip(enrollment: exit_assessment.enrollment, client: exit_assessment.enrollment.client, date: exit_assessment.assessment_date)
        exit_assessment.save_in_progress

        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('ANY_EXIT_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_EXIT_INCOMPLETE')
      end

      it 'household with one exited (e3) and one unexited with a submitted exit assessment (e2, bad state)' do
        exit_assessment.update(enrollment: e2)
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('ANY_EXIT_INCOMPLETE')
        expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('OWN_EXIT_INCOMPLETE')
      end

      describe 'two exited members' do
        let!(:exit2) { create :hmis_hud_exit, data_source: ds1, enrollment: e2, client: e2.client }
        it 'household with one exited (e3) and one exited with a submitted exit assessment (e2)' do
          exit_assessment.update(enrollment: e2)
          expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e3)).to eq('EXITED')
          expect(Types::HmisSchema::Enums::EnrollmentStatus.from_enrollment(e2)).to eq('EXITED')
        end
      end
    end
  end
end
