require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Assessment, type: :model do
  let!(:assessment) { create(:hmis_hud_assessment_with_defaults) }

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'in process assessments' do
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
end
