require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Assessment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'saved assessments' do
    let!(:assessment) { create(:hmis_hud_assessment) }

    before(:each) do
      enrollment = assessment.enrollment
      create(:hmis_assessment_question, data_source: enrollment.data_source, enrollment: enrollment, assessment: assessment)
      create(:hmis_assessment_result, data_source: enrollment.data_source, enrollment: enrollment, assessment: assessment)

      assessment.save
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
