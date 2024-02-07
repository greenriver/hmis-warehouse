###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2022::QuestionFour, type: :model do
  include_context 'dq context FY2022'

  # DEPRECATED_FY2024 - these are expected to fail until we re-write the report
  # before(:all) do
  #   default_setup
  #   run(default_filter, HudDataQualityReport::Generators::Fy2022::QuestionFour::QUESTION_NUMBER)
  # end

  # after(:all) do
  #   cleanup
  # end

  # it 'counts one income' do
  #   answer = report_result.answer(question: 'Q4', cell: 'C3').summary
  #   expect(answer).to eq('0.7500')
  # end
end
