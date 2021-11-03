###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionNine, type: :model do
  include_context 'caper context FY2021'

  before(:all) do
    default_setup
    run(night_by_night_shelter, HudApr::Generators::Caper::Fy2021::QuestionNine::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic was tested in the APR
  it 'runs' do
    expect(report_result.answer(question: 'Q9a', cell: 'B6').summary).not_to eq(nil)
  end

  describe 'Q9a: Number of Persons Contacted' do
  end

  describe 'Q9b: Number of Persons Engaged' do
  end
end
