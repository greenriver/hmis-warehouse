require 'rails_helper'
require_relative 'apr_context.rb'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionFive, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup

    HudApr::Generators::Apr::Fy2020::QuestionFive.new(options: default_options).run!
  end

  after(:all) do
    cleanup
  end

  it 'counts people served' do
    expect(report_result.answer(question: 'Q5a', cell: 'B1').summary).to eq(4)
  end

  it 'counts adults' do
    expect(report_result.answer(question: 'Q5a', cell: 'B2').summary).to eq(2)
  end

  it 'counts children' do
    expect(report_result.answer(question: 'Q5a', cell: 'B3').summary).to eq(1)
  end

  it 'counts missing age' do
    expect(report_result.answer(question: 'Q5a', cell: 'B4').summary).to eq(1)
  end

  it 'counts leavers' do
    expect(report_result.answer(question: 'Q5a', cell: 'B5').summary).to eq(2)
  end

  it 'counts adult leavers' do
    expect(report_result.answer(question: 'Q5a', cell: 'B6').summary).to eq(0)
  end

  it 'counts adult head of household leavers' do
    expect(report_result.answer(question: 'Q5a', cell: 'B7').summary).to eq(2)
  end

  it 'counts stayers' do
    expect(report_result.answer(question: 'Q5a', cell: 'B8').summary).to eq(2)
  end

  it 'counts adult stayers' do
    expect(report_result.answer(question: 'Q5a', cell: 'B9').summary).to eq(2)
  end

  it 'counts veterans' do
    expect(report_result.answer(question: 'Q5a', cell: 'B10').summary).to eq(0)
  end

  it 'counts chronically homeless persons' do
    expect(report_result.answer(question: 'Q5a', cell: 'B11').summary).to eq(0)
  end

  it 'counts under 25' do
    expect(report_result.answer(question: 'Q5a', cell: 'B12').summary).to eq(1)
  end

  it 'counts under 25 with children' do
    expect(report_result.answer(question: 'Q5a', cell: 'B13').summary).to eq(0)
  end

  it 'counts adult heads of household' do
    expect(report_result.answer(question: 'Q5a', cell: 'B14').summary).to eq(2)
  end

  it 'counts child and unknown age heads of household' do
    expect(report_result.answer(question: 'Q5a', cell: 'B15').summary).to eq(2)
  end

  it 'counts heads of household and stayers over 365 days' do
    expect(report_result.answer(question: 'Q5a', cell: 'B16').summary).to eq(2)
  end

  def report_result
    HudReports::ReportInstance.last
  end
end
