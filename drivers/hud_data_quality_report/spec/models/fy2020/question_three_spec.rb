###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2020::QuestionThree, type: :model do
  include_context 'dq context'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2020::QuestionThree::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'hoh denominator is correct' do
    # Test data has a dummy CoC code, so all HoH enrollments are incorrect
    expect(report_result.answer(question: 'Q3', cell: 'C5').summary).to eq('1.0000')
  end
end
