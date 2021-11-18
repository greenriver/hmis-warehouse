###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_apr_context'

RSpec.describe 'Datalab 2021 APR - PSH', type: :model do
  include_context 'datalab apr context'

  before(:all) do
    setup
    run(project_type_filter(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:psh]))
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match
      ],
    )
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q5a',
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6a',
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6b',
    )
  end

  it 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6c',
    )
  end

  it 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6d',
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6e',
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q6f',
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q7a',
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q7b',
      skip: [
        'B3', # FIXME, Pending AAQ
        'D3', # FIXME, Pending AAQ
        'B4', # FIXME, Pending AAQ
        'D4', # FIXME, Pending AAQ
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q8a',
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q8b',
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q9b',
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q10a',
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q10b',
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q10c',
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q11',
    )
  end

  it 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q12a',
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q12b',
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13a1',
    )
  end

  it 'Q13a2' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13a2',
    )
  end

  it 'Q1ba1' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13b1',
    )
  end

  it 'Q13b2' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13b2',
    )
  end

  it 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13c1',
    )
  end

  it 'Q13c2' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q13c2',
    )
  end

  it 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q14a',
    )
  end

  it 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q14b',
    )
  end

  it 'Q15' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q16',
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q17',
    )
  end

  it 'Q18' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q18',
    )
  end

  it 'Q19a1' do
    compare_results(
      file_path: result_file_prefix + 'psh',
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
      file_path: result_file_prefix + 'psh',
      question: 'Q19a2',
      skip: [
        'F2', # FIXME
        'G2', # FIXME
        'H2', # FIXME
        'J2', # FIXME
        'F3', # FIXME
        'H4', # FIXME
        'H7', # FIXME
      ],
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
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
      file_path: result_file_prefix + 'psh',
      question: 'Q20a',
    )
  end

  it 'Q20b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q20b',
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q21',
      skip: [
        'B10', # FIXME
        'D10', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B12', # FIXME
        'B13', # FIXME
        'D12', # FIXME
        'C14', # FIXME
        'B17', # FIXME
        'D17', # FIXME
      ],
    )
  end

  it 'Q22a1' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22a1',
    )
  end

  it 'Q22b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
      ],
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22c',
      skip: [
        'D11', # FIXME
        'E11', # FIXME
      ],
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22e',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'B13', # FIXME
        'C13', # FIXME
      ],
    )
  end

  it 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q23c',
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
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
      file_path: result_file_prefix + 'psh',
      question: 'Q25b',
      skip: [
        'B4', # FIXME
        'E4', # FIXME
        'B7', # FIXME
        'E7', # FIXME
      ],
    )
  end

  it 'Q25c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25c',
    )
  end

  it 'Q25d' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25d',
    )
  end

  it 'Q25e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
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
      file_path: result_file_prefix + 'psh',
      question: 'Q25f',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q25g' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25g',
    )
  end

  it 'Q25h' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25h',
    )
  end

  it 'Q25i' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25i',
    )
  end

  it 'Q26a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26a',
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26b',
    )
  end

  it 'Q26c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26c',
    )
  end

  it 'Q26d' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26d',
    )
  end

  it 'Q26e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26e',
      skip: [
        'C6', # FIXME
        'C9', # FIXME
      ],
    )
  end

  it 'Q26f' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26f',
    )
  end

  it 'Q26g' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26g',
    )
  end

  it 'Q26h' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q26h',
    )
  end

  it 'Q27a' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27a',
    )
  end

  it 'Q27b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27b',
    )
  end

  it 'Q27c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27c',
      skip: [
        'C5', # FIXME
        'E5', # FIXME
      ],
    )
  end

  it 'Q27d' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27d',
    )
  end

  it 'Q27e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27e',
    )
  end

  it 'Q27f' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27f',
    )
  end

  it 'Q27g' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27g',
      skip: [
        'D17', # FIXME
      ],
    )
  end

  it 'Q27h' do
    compare_results(
      file_path: result_file_prefix + 'psh',
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
      file_path: result_file_prefix + 'psh',
      question: 'Q27i',
      skip: [
        'E2', # FIXME formatting
        'E3', # FIXME formatting
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
