###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwentySeven, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwentySeven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic should already have been tested
  it 'runs' do
    expect(report_result.answer(question: 'Q27c', cell: 'B9').summary).to eq(8)
  end

  describe 'Q27a: Age of Youth' do
  end

  describe 'Q27b: Parenting Youth' do
  end

  describe 'Q27c: Gender - Youth' do
  end

  describe 'Q27d: Living Situation - Youth' do
  end

  describe 'Q27e: Length of Participation - Youth' do
  end

  describe 'Q27f: Exit Destination - Youth' do
  end

  describe 'Q27g: Cash Income - Sources - Youth' do
  end

  describe 'Q27h: Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status - Youth' do
  end

  describe 'Q27i: Disabling Conditions and Income for Youth at Exit' do
  end
end
