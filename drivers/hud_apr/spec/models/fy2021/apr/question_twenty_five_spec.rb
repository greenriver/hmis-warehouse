###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwentyFive, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwentyFive::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic should already have been tested
  it 'runs' do
    expect(report_result.answer(question: 'Q25a', cell: 'B3').summary).to eq(2)
  end

  describe 'Q25a: Number of Veterans' do
  end

  describe 'Q25b: Number of Veteran Households' do
  end

  describe 'Q25c: Gender – Veterans' do
  end

  describe 'Q25d: Age – Veterans' do
  end

  describe 'Q25e: Physical and Mental Health Conditions – Veterans' do
  end

  describe 'Q25f: Cash Income Category - Income Category - by Start and Annual /Exit Status – Veterans' do
  end

  describe 'Q25g: Type of Cash Income Sources – Veterans' do
  end

  describe 'Q25h: Type of Non-Cash Benefit Sources – Veterans' do
  end

  describe 'Q25i: Exit Destination – Veterans' do
  end
end
