###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionSeventeen, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionSeventeen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q17: Cash Income - Sources' do
    it 'sees an entry assessment with earned income' do
      expect(report_result.answer(question: 'Q17', cell: 'B2').summary).to eq(1)
    end

    it 'sees an annual assessment with earned income' do
      expect(report_result.answer(question: 'Q17', cell: 'C2').summary).to eq(1)
    end
  end
end
