###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_context'

RSpec.describe 'Datalab 2021 APR - rrh 2 projects', type: :model do
  include_context 'datalab apr context'

  before(:all) do
    setup
    run(project_type_filter(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:rrh]))
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    question = 'Q4a'
    goals = goals(
      file_path: result_file_prefix + 'rrh_2',
      question: question,
    )
    compare_columns(goal: goals, question: question, column_names: ['C', 'D'])
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q5a',
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6a',
      skip: [
        'C3', # FIXME
        'D3', # FIXME
        'C6', # FIXME
        'E6', # FIXME
        'C7', # FIXME
        'E7', # FIXME
        'F6', # FIXME
        'F7', # FIXME
      ],
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6b',
      skip: [
        'B4', # FIXME
        'B6', # FIXME
        'C2', # FIXME
        'C4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'C6', # FIXME
      ],
    )
  end

  it 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6c',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6d',
      skip: [
        'D4', # FIXME`
        'F4', # FIXME`
        'G4', # FIXME`
        'H4', # FIXME`
        'H5', # FIXME`
      ],
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6e',
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q6f',
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q7a',
      skip: [
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q7b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q8a',
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q8b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q9b',
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q10a',
      skip: [
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q10b',
      skip: [
        'C5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q10c',
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q11',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B12', # FIXME
        'C12', # FIXME
      ],
    )
  end

  it 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q12a',
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q12b',
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13a1',
    )
  end

  it 'Q13a2' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13a2',
    )
  end

  it 'Q1ba1' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13b1',
    )
  end

  it 'Q13b2' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13b2',
    )
  end

  it 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13c1',
    )
  end

  it 'Q13c2' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q13c2',
    )
  end

  it 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q14a',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'E5', # FIXME
      ],
    )
  end

  it 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q14b',
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'B4', # FIXME
        'D4', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
      ],
    )
  end

  it 'Q15' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q16',
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q17',
    )
  end

  it 'Q18' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q18',
      skip: [
        'B5', # FIXME
        'D5', # FIXME,
      ],
    )
  end

  it 'Q19a1' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q19a1',
      skip: [
        'F2', # FIXME
        'F3', # FIXME
        'H7', # FIXME
      ],
    )
  end

  it 'Q19a2' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q19a2',
      skip: [
        'G2', # FIXME
        'H2', # FIXME
        'H4', # FIXME
      ],
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q19b',
      skip: [
        'C12', # FIXME
        'D12', # FIXME
        'G12', # FIXME
        'H12', # FIXME
        'C13', # FIXME
        'D13', # FIXME
        'C14', # FIXME
        'D14', # FIXME
      ],
    )
  end

  it 'Q20a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q20a',
    )
  end

  it 'Q20b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q20b',
      skip: [
        'C5', # FIXME
        'C6', # FIXME
      ],
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q21',
      skip: [
        'C2', # FIXME
        'C3', # FIXME
        'B10', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B12', # FIXME
        'D12', # FIXME
        'C14', # FIXME
        'C15', # FIXME
        'D16', # FIXME
        'B17', # FIXME
        'C17', # FIXME
      ],
    )
  end

  it 'Q22a1' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q22a1',
    )
  end

  it 'Q22b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q22b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
      ],
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q22c',
      skip: [
        'B7', # FIXME
        'D7', # FIXME
        'F7', # FIXME
        'B8', # FIXME
        'D8', # FIXME
        'F8', # FIXME
        'B9', # FIXME
        'E9', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'D10', # FIXME
        'F10', # FIXME
        'B11', # FIXME
        'C11', # FIXME
        'D11', # FIXME
        'E11', # FIXME
        'F11', # FIXME
        'B12', # FIXME
        'C12', # FIXME
        'D12', # FIXME
        'E12', # FIXME
        'F12', # FIXME
        'B13', # FIXME
        'C13', # FIXME
        'D13', # FIXME
        'E13', # FIXME
        'F13', # FIXME
      ],
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q22e',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B7', # FIXME
        'F7', # FIXME
        'B13', # FIXME
        'C13', # FIXME
        'F13', # FIXME
      ],
    )
  end

  it 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q23c',
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25a',
      skip: [
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'E6', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'E7', # FIXME
      ],
    )
  end

  it 'Q25b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25b',
      skip: [
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'E4', # FIXME
        'E6', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'E7', # FIXME
      ],
    )
  end

  it 'Q25c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25c',
    )
  end

  it 'Q25d' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25d',
    )
  end

  it 'Q25e' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25e',
      skip: [
        'C4', # FIXME
        'D4', # FIXME
        'C6', # FIXME
        'C9', # FIXME
      ],
    )
  end

  it 'Q25f' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25f',
      skip: [
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'C7', # FIXME
        'B8', # FIXME
      ],
    )
  end

  it 'Q25g' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25g',
    )
  end

  it 'Q25h' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25h',
    )
  end

  it 'Q25i' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q25i',
    )
  end

  it 'Q26a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26a',
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26b',
    )
  end

  it 'Q26c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26c',
    )
  end

  it 'Q26d' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26d',
    )
  end

  it 'Q26e' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26e',
      skip: [
        'C6', # FIXME
        'C9', # FIXME
      ],
    )
  end

  it 'Q26f' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26f',
    )
  end

  it 'Q26g' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26g',
    )
  end

  it 'Q26h' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q26h',
    )
  end

  it 'Q27a' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27a',
    )
  end

  it 'Q27b' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27b',
    )
  end

  it 'Q27c' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27c',
      skip: [
        'C5', # FIXME
        'E5', # FIXME
      ],
    )
  end

  it 'Q27d' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27d',
    )
  end

  it 'Q27e' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27e',
    )
  end

  it 'Q27f' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27f',
    )
  end

  it 'Q27g' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27g',
      skip: [
        'D17', # FIXME
      ],
    )
  end

  it 'Q27h' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27h',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
        'B10', # FIXME
        'D10', # FIXME
        'D12', # FIXME
      ],
    )
  end

  it 'Q27i' do
    compare_results(
      file_path: result_file_prefix + 'rrh_2',
      question: 'Q27i',
      skip: [
        'E2', # FIXME
        'E3', # FIXME
        'G6', # FIXME
        'H6', # FIXME
        'K6', # FIXME
        'L6', # FIXME
        'G10', # FIXME
        'H10', # FIXME
        'K10', # FIXME
        'L10', # FIXME
        'B13', # FIXME
        'D13', # FIXME
        'E13', # FIXME
        'G13', # FIXME
        'H13', # FIXME
        'B14', # FIXME
        'D14', # FIXME
        'K14', # FIXME
        'L14', # FIXME
      ],
    )
  end
end
