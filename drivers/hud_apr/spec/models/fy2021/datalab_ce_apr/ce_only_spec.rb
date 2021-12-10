###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_ce_apr_context'

RSpec.describe 'Datalab 2021 CE APR - CE Only', type: :model do
  include_context 'datalab ce apr context'

  before(:all) do
    setup
    run(ce_only_filter)
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    question = 'Q4a'
    goals = goals(
      file_path: result_file_prefix + 'ce_only',
      question: question,
    )
    compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q5a',
      skip: [
        'B1', # FIXME
        'B3', # FIXME
      ],
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q6a',
      skip: [
        'F2', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'F4', # FIXME
        'F6', # FIXME
        'E8', # FIXME
        'F8', # FIXME
      ],
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q7a',
      skip: [
        'C2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'F6', # FIXME
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q8a',
      skip: [
        'C2', # FIXME
        'D2', # FIXME
      ],
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9a',
      skip: [
        'C4', # FIXME
        'D4', # FIXME
        'C5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9b',
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
      ],
    )
  end

  it 'Q9c' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9c',
    )
  end

  it 'Q9d' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9d',
      skip: [
        'C9', # FIXME
        'D9', # FIXME
        'C16', # FIXME
        'D16', # FIXME
        'C18', # FIXME
        'D18', # FIXME
        'B21', # FIXME
        'C21', # FIXME
        'E21', # FIXME
        'B23', # FIXME rounding difference
        'C23', # FIXME rounding difference
        'D23', # FIXME
      ],
    )
  end

  it 'Q10' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q10',
      skip: [
        'B6', # FIXME
        'B14', # FIXME
        'D14', # FIXME
      ],
    )
  end
end
