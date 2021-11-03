###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionNine, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(night_by_night_shelter, HudApr::Generators::Apr::Fy2021::QuestionNine::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q9a: Number of Persons Contacted' do
    it 'total of two contacts' do
      expect(report_result.answer(question: 'Q9a', cell: 'B6').summary).to eq(3)
    end
  end

  describe 'Q9b: Number of Persons Engaged' do
    it 'total of one engagement' do
      expect(report_result.answer(question: 'Q9b', cell: 'B6').summary).to eq(1)
    end
  end
end
