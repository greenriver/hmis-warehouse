###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2020::QuestionFifteen, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2020::QuestionFifteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic was tested in the APR
  it 'runs' do
    expect(report_result.answer(question: 'Q15', cell: 'B3').summary).not_to eq(nil)
  end

  describe 'Q15: Living Situation' do
  end
end
