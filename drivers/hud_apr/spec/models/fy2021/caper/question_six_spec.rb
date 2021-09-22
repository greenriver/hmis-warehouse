###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionSix, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
  end

  after(:all) do
    cleanup
  end

  describe 'With default project' do
    before(:all) do
      run(default_filter, HudApr::Generators::Caper::Fy2021::QuestionSix::QUESTION_NUMBER)
    end

    # This is just a smoke test, the underlying logic was tested in the APR
    it 'runs' do
      expect(report_result.answer(question: 'Q6a', cell: 'E3').summary).not_to eq(nil)
    end

    describe 'Q6a: Personally Identifiable Information' do
    end

    describe 'Q6b: Data Quality: Universal Data Elements' do
    end

    describe 'Q6c: Data Quality: Income and Housing Data Quality' do
    end

    describe 'Q6d: Data Quality: Chronic Homelessness' do
    end

    describe 'Q6e: Data Quality: Timeliness' do
    end
  end

  describe 'Q6f: Data Quality: Inactive Records: Street Outreach and Emergency Shelter' do
  end
end
