###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionSeven, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionSeven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q7a: Number of Persons Served' do
    it 'counts adults' do
      expect(report_result.answer(question: 'Q7a', cell: 'B2').summary).to eq(6)
    end

    it 'counts adults without children' do
      expect(report_result.answer(question: 'Q7a', cell: 'C2').summary).to eq(5)
    end

    it 'counts adults with children' do
      expect(report_result.answer(question: 'Q7a', cell: 'D2').summary).to eq(1)
    end
  end

  describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
    # TODO: needs a 2, 3, 8, 9, 10, or 13 project
  end
end
