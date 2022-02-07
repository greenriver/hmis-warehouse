###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionSeven, type: :model do
  include_context 'caper context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2021::QuestionSeven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic was tested in the APR
  it 'runs' do
    expect(report_result.answer(question: 'Q7a', cell: 'B2').summary).not_to eq(nil)
    expect(report_result.answer(question: 'Q7b', cell: 'B2').summary).not_to eq(nil)
  end

  describe 'Q7a: Number of Persons Served' do
  end

  describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
  end
end
