###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2020::QuestionEightToSixteen, type: :model do
  include_context 'path context'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2020::QuestionEightToSixteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts active clients' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B2').summary).to eq(7)
  end

  it 'counts new SO clients' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B3').summary).to eq(2)
  end

  it 'counts new services only clients' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B4').summary).to eq(2)
  end

  it 'counts total new clients' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B5').summary).to eq(4)
  end

  it 'counts contacts before enrollment' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B6').summary).to eq(3)
  end

  it 'counts total contacts' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B7').summary).to eq(5)
  end

  it 'counts ineligible' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B8').summary).to eq(1)
  end

  it 'counts not found' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B9').summary).to eq(0)
  end

  it 'counts new enrollees' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B10').summary).to eq(1)
  end

  it 'counts enrollees' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B11').summary).to eq(2)
  end

  it 'counts enrollees receiving community mental health' do
    expect(report_result.answer(question: 'Q8-Q16', cell: 'B11').summary).to eq(2)
  end
end
