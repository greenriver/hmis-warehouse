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
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6b',
    )
  end

  it 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6c',
    )
  end

  it 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6d',
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q6e',
      skip: [ # pending AAQ
        'C2',
        'C6',
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
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q7b',
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
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q10b',
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
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q11',
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
    )
  end

  it 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q14b',
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

  xit 'Q24' do # pending AAQ
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q24',
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q25a',
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'hp',
      question: 'Q26b',
    )
  end
end
