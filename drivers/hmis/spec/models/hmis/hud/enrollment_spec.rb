require 'rails_helper'
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
end
