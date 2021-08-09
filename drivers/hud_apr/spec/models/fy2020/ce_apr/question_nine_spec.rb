###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2020::QuestionNine, type: :model do
  include_context 'apr context'

  # before(:all) do
  #   default_setup(default_setup_path)
  #   run(night_by_night_shelter, HudApr::Generators::CeApr::Fy2020::QuestionNine::QUESTION_NUMBER)
  # end

  # after(:all) do
  #   cleanup
  # end

  # describe 'Q9a: Number of Persons Contacted' do
  #   it 'total of two contacts' do
  #     expect(report_result.answer(question: 'Q9a', cell: 'B6').summary).to eq(3)
  #   end
  # end

  # describe 'Q9b: Number of Persons Engaged' do
  #   it 'total of one engagement' do
  #     expect(report_result.answer(question: 'Q9b', cell: 'B6').summary).to eq(1)
  #   end
  # end
end
