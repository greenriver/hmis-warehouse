###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2020::QuestionThirteen, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2020::QuestionThirteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic was tested in the APR
  it 'runs' do
    expect(report_result.answer(question: 'Q13a1', cell: 'B2').summary).not_to eq(nil)
  end

  describe 'Q13a1: Physical and Mental Health Conditions at Start' do
  end

  describe 'Q13b1: Physical and Mental Health Conditions at Exit' do
  end

  describe 'Q13c1: Physical and Mental Health Conditions for Stayers' do
  end
end
