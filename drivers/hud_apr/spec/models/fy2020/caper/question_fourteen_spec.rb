###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2020::QuestionFourteen, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2020::QuestionFourteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic was tested in the APR
  it 'runs' do
    expect(report_result.answer(question: 'Q14a', cell: 'B2').summary).not_to eq(nil)
  end

  describe 'Q14a: Domestic Violence History' do
  end

  describe 'Q14b: Persons Fleeing Domestic Violence' do
  end
end
