###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2020::QuestionTen, type: :model do
  include_context 'apr context'

  # before(:all) do
  #   default_setup(default_setup_path)
  #   run(default_filter, HudApr::Generators::CeApr::Fy2020::QuestionTen::QUESTION_NUMBER)
  # end

  # after(:all) do
  #   cleanup
  # end

  # describe 'Q10a: Gender of Adults' do
  #   it 'Counts males' do
  #     expect(report_result.answer(question: 'Q10a', cell: 'B2').summary).to eq(2)
  #   end

  #   it 'Counts females' do
  #     expect(report_result.answer(question: 'Q10a', cell: 'B3').summary).to eq(2)
  #   end

  #   it 'Counts Total' do
  #     expect(report_result.answer(question: 'Q10a', cell: 'B9').summary).to eq(6)
  #   end
  # end

  # describe 'Q10b: Gender of Children' do
  #   it 'Counts MTF' do
  #     expect(report_result.answer(question: 'Q10b', cell: 'B4').summary).to eq(1)
  #   end

  #   it 'Counts FTM' do
  #     expect(report_result.answer(question: 'Q10b', cell: 'B5').summary).to eq(1)
  #   end

  #   it 'Counts Total' do
  #     expect(report_result.answer(question: 'Q10b', cell: 'B9').summary).to eq(2)
  #   end
  # end

  # describe 'Q10c: Gender of Persons Missing Age Information' do
  #   it 'Counts total households' do
  #     expect(report_result.answer(question: 'Q10c', cell: 'B9').summary).to eq(1)
  #   end
  # end
end
