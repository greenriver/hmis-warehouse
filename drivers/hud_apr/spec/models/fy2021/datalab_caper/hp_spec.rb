###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_caper_context'

RSpec.describe 'Datalab 2021 CAPER - HP', type: :model do
  include_context 'datalab caper context'

  before(:all) do
    setup
    run(project_type_filter(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:prevention]))
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match
      ],
    )
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q5a',
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
      question: 'Q6d',
      skip: [
        'B5', # FIXME
      ],
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6e',
      skip: [
        'C2', # FIXME
        'C6', # FIXME
      ],
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6f',
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
      question: 'Q7b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'F2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'E4', # FIXME
        'F4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'E5', # FIXME
        'F5', # FIXME
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q8a',
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q8b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'F2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'E4', # FIXME
        'F4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'E5', # FIXME
        'F5', # FIXME
      ],
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q9b',
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q10a',
      skip: [
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q10b',
      skip: [
        'C5', # FIXME
        'D5', # FIXME
      ],
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q10c',
    )
  end

  it 'Q10d' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q10d',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
        'E5', # FIXME
        'G5', # FIXME
        'E8', # FIXME
        'H8', # FIXME
        'C9', # FIXME
        'E9', # FIXME
        'G9', # FIXME
        'H9', # FIXME
      ],
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
      question: 'Q12a',
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q12b',
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q13a1',
    )
  end

  it 'Q13b1' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q13b1',
    )
  end

  it 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q13c1',
    )
  end

  it 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q16',
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q17',
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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
      file_path: result_file_prefix + 'hp',
      question: 'Q20a',
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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

  it 'Q22a2' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q22a2',
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q22c',
    )
  end

  it 'Q22d' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q22d',
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q22e',
    )
  end

  it 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q23c',
    )
  end

  it 'Q24' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q24',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B7', # FIXME
        'C7', # FIXME
      ],
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
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

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q26b',
    )
  end
end
