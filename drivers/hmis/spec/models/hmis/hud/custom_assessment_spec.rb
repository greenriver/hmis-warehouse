###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::CustomAssessment, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'in progress assessments' do
    let!(:assessment) { create(:hmis_custom_assessment_with_defaults) }

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
      expect(assessment.custom_form).not_to be_present
    end
  end

  describe 'saved assessments' do
    let!(:assessment) { create(:hmis_custom_assessment_with_defaults) }

    before(:each) do
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
  end
end
