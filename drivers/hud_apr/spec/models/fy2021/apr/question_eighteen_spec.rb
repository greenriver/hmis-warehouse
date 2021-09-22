###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionEighteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionEighteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q18: Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status' do
    it 'sees earned income in annual assessment' do
      expect(report_result.answer(question: 'Q18', cell: 'C2').summary).to eq(1)
    end

    it 'sees income at start and annual assessment' do
      expect(report_result.answer(question: 'Q18', cell: 'C12').summary).to eq(1)
    end
  end
end
