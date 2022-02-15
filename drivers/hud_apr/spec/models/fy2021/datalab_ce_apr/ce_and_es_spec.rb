###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_ce_apr_context'

RSpec.describe 'Datalab 2021 CE APR - CE and ES', type: :model do
  include_context 'datalab ce apr context'

  before(:all) do
    setup
    run(ce_and_es_filter)
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    question = 'Q4a'
    goals = goals(
      file_path: result_file_prefix + 'ce_and_es',
      question: question,
    )
    compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q5a',
      skip: [
        'B1', # FIXME
        'B3', # FIXME
        'B4', # FIXME
      ],
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q6a',
      skip: [
        'B2', # FIXME
        'E2', # FIXME
        'F2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'E4', # FIXME
        'F4', # FIXME
        'F5', # FIXME
        'B6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
        'C7', # FIXME
        'E7', # FIXME
        'F7', # FIXME
        'E8', # FIXME
        'F8', # FIXME
      ],
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q7a',
      skip: [
        'C2', # FIXME
        'D2', # FIXME
        'F2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'F4', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'F6', # FIXME
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q8a',
      skip: [
        'C2', # FIXME
        'D2', # FIXME
        'F2', # FIXME
      ],
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q9a',
      skip: [
        'C3', # FIXME
        'D3', # FIXME
        'F3', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'F5', # FIXME
      ],
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q9b',
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'C4', # FIXME
      ],
    )
  end

  it 'Q9c' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q9c',
    )
  end

  it 'Q9d' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q9d',
      skip: [
        'C2', # FIXME
        'D2', # FIXME
        'F2', # FIXME
        'C9', # FIXME
        'D9', # FIXME
        'C16', # FIXME
        'D16', # FIXME
        'F16', # FIXME
        'C18', # FIXME
        'D18', # FIXME
        'B21', # FIXME
        'C21', # FIXME
        'E21', # FIXME
        'C22', # FIXME
        'D22', # FIXME
        'F22', # FIXME
        'B23', # FIXME rounding difference
        'C23', # FIXME
        'D23', # FIXME
      ],
    )
  end

  it 'Q10' do
    compare_results(
      file_path: result_file_prefix + 'ce_and_es',
      question: 'Q10',
      skip: [
        'B6', # FIXME
      ],
    )
  end
end
