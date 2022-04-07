###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q6a',
      skip: [ # Pending AAQ
        'D3',
        'E3',
        'F3',
        'E8',
        'F8',
      ],
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q7a',
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q8a',
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q9b',
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
        'B23', # Rounding difference
      ],
    )
  end

  it 'Q10' do
    compare_results(
      file_path: result_file_prefix + 'ce_only',
      question: 'Q10',
    )
  end
end
