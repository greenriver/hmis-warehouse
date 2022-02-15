###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

  it 'Q13b1' do
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
    )
  end

  it 'Q19a2' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q19a2',
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q19b',
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
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22c',
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q22e',
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
    )
  end

  it 'Q25b' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25b',
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
    )
  end

  it 'Q25f' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q25f',
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
    )
  end

  it 'Q27h' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27h',
    )
  end

  it 'Q27i' do
    compare_results(
      file_path: result_file_prefix + 'psh',
      question: 'Q27i',
    )
  end
end
