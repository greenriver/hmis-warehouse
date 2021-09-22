###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionTwentyTwo, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2021::QuestionTwentyTwo::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q22a2: Length of Participation – ESG Projects' do
    it 'counts all clients' do
      expect(report_result.answer(question: 'Q22a2', cell: 'B16').summary).to eq(9)
    end

    it 'counts leavers' do
      expect(report_result.answer(question: 'Q22a2', cell: 'C16').summary).to eq(4)
    end

    it 'counts stayers' do
      expect(report_result.answer(question: 'Q22a2', cell: 'D16').summary).to eq(5)
    end
  end

  describe 'Q22c: Length of Time between Project Start Date and Housing Move-in Date' do
    # Tested in APR
  end

  describe 'Q22d: Length of Participation by Household Type' do
    it 'counts all clients' do
      expect(report_result.answer(question: 'Q22d', cell: 'B16').summary).to eq(9)
    end
  end

  describe 'Q22e: Length of Time Prior to Housing - based on 3.917 Date Homelessness Started' do
    # Tested in APR
  end
end
