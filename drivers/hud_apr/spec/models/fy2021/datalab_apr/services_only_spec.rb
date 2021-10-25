###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_apr_context'

RSpec.describe 'Datalab 2021 APR - services_only', type: :model do
  include_context 'datalab apr context'

  before(:all) do
    setup
    run(project_type_filter(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:services_only]))
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match

        'H2', # FIXME
      ],
    )
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q5a',
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q6a',
      skip: [
        'C3', # FIXME
        'D3', # FIXME
        'C6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
        'C7', # FIXME
        'E7', # FIXME
        'F7', # FIXME
      ],
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q6b',
      skip: [
        'C2', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
      ],
    )
  end

  it 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q6d',
      skip: [
        'B5', # FIXME
      ],
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q6e',
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q6f',
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q7a',
      skip: [
        'B4', # FIXME`
        'D4', # FIXME`
        'B5', # FIXME`
        'C5', # FIXME`
      ],
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q7b',
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q8a',
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q8b',
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q9b',
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q10a',
      skip: [
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q10b',
      skip: [
        'C5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q10c',
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q12a',
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q12b',
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13a1',
    )
  end

  it 'Q13a2' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13a2',
    )
  end

  it 'Q1ba1' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13b1',
    )
  end

  it 'Q13b2' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13b2',
    )
  end

  it 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13c1',
    )
  end

  it 'Q13c2' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q13c2',
    )
  end

  it 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q14b',
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q16',
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q17',
    )
  end

  it 'Q18' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q18',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q19a1' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q20a',
    )
  end

  it 'Q20b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q20b',
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q21',
      skip: [
        'B10', # FIXME
        'D10', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B12', # FIXME
        'D12', # FIXME
        'C14', # FIXME
        'B17', # FIXME
        'D17', # FIXME
      ],
    )
  end

  it 'Q22a1' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q22a1',
    )
  end

  it 'Q22b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q22b',
      skip: [
        'B2', # FIXME rounding?
        'C2', # FIXME formatting
      ],
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q22c',
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q22e',
    )
  end

  it 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q23c',
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q25a',
      skip: [
        'B4', # FIXME
        'B5', # FIXME
        'D4', # FIXME
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
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q25c',
    )
  end

  it 'Q25d' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q25d',
    )
  end

  it 'Q25e' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
      question: 'Q25f',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q25g' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q25g',
    )
  end

  it 'Q25h' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q25h',
    )
  end

  it 'Q25i' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q25i',
    )
  end

  it 'Q26a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26a',
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26b',
    )
  end

  it 'Q26c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26c',
    )
  end

  it 'Q26d' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26d',
    )
  end

  it 'Q26e' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26e',
      skip: [
        'C6', # FIXME
        'C9', # FIXME
      ],
    )
  end

  it 'Q26f' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26f',
    )
  end

  it 'Q26g' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26g',
    )
  end

  it 'Q26h' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q26h',
    )
  end

  it 'Q27a' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27a',
    )
  end

  it 'Q27b' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27b',
    )
  end

  it 'Q27c' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27c',
      skip: [
        'C5', # FIXME
        'E5', # FIXME,
      ],
    )
  end

  it 'Q27d' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27d',
    )
  end

  it 'Q27e' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27e',
    )
  end

  it 'Q27f' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27f',
    )
  end

  it 'Q27g' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
      question: 'Q27g',
      skip: [
        'D17', # FIXME
      ],
    )
  end

  it 'Q27h' do
    compare_results(
      file_path: result_file_prefix + 'services_only',
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
      file_path: result_file_prefix + 'services_only',
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
