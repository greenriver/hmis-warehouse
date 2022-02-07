###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionThirteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionThirteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q13a1: Physical and Mental Health Conditions at Start' do
    it 'sees both drug and alcohol abuse as one condition' do
      expect(report_result.answer(question: 'Q13a1', cell: 'B3').summary).to eq(0)
      expect(report_result.answer(question: 'Q13a1', cell: 'B4').summary).to eq(0)
      expect(report_result.answer(question: 'Q13a1', cell: 'B5').summary).to eq(1)
    end
  end

  describe 'Q13b1: Physical and Mental Health Conditions at Exit' do
  end

  describe 'Q13c1: Physical and Mental Health Conditions for Stayers' do
  end

  describe 'Q13a2: Number of Conditions at Start' do
    it 'sees drug and alcohol abuse as separate conditions' do
      expect(report_result.answer(question: 'Q13a2', cell: 'B4').summary).to eq(1)
    end
  end

  describe 'Q13b2: Number of Conditions at Exit' do
  end

  describe 'Q13c2: Number of Conditions for Stayers' do
  end
end
