require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Assessment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'in process assessments' do
    let!(:assessment) { create(:hmis_hud_assessment_with_defaults) }

    before(:each) do
      assessment.build_wip(enrollment: assessment.enrollment, client: assessment.enrollment.client, date: assessment.assessment_date)
      assessment.save_in_progress
    end

    it 'cleans up dependent wip after destroy' do
      assessment.reload
      expect(assessment.wip).to be_present

      assessment.destroy
      assessment.reload
      expect(assessment.wip).not_to be_present
      expect(assessment.assessment_detail).not_to be_present
    end
  end

  describe 'saved assessments' do
    let!(:assessment) { create(:hmis_hud_assessment) }

    before(:each) do
      enrollment = assessment.enrollment
      create(:hmis_assessment_question, data_source: enrollment.data_source, enrollment: enrollment, assessment: assessment)
      create(:hmis_assessment_result, data_source: enrollment.data_source, enrollment: enrollment, assessment: assessment)

      assessment.save_not_in_progress
    end

    it 'preserve shared data after destroy' do
      assessment.destroy
      assessment.reload

      [
        :enrollment,
        :client,
        :user,
      ].each do |assoc|
        expect(assessment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end
    end

    it 'destroy dependent data' do
      assessment.reload
      [
        :assessment_questions,
        :assessment_results,
      ].each do |assoc|
        expect(assessment.send(assoc)).to be_present, "expected #{assoc} to be present"
      end

      assessment.destroy
      assessment.reload

      [
        :assessment_questions,
        :assessment_results,
      ].each do |assoc|
        expect(assessment.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
      end
    end
  end
end
