###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_caper_context'

RSpec.describe 'Datalab 2021 CAPER - SO', type: :model do
  include_context 'datalab caper context'

  before(:all) do
    setup
    run(project_type_filter(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:so]))
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match
      ],
    )
  end

  xxit 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q5a',
    )
  end

  xxit 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6a',
    )
  end

  xxit 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6b',
    )
  end

  xxit 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6c',
    )
  end

  xxit 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6d',
    )
  end

  xxit 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6e',
    )
  end

  xxit 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6f',
    )
  end

  xxit 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q7a',
    )
  end

  xxit 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q7b',
    )
  end

  xxit 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q8a',
    )
  end

  xxit 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q8b',
    )
  end

  xxit 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q9a',
    )
  end

  xxit 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q9b',
    )
  end

  xxit 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10a',
    )
  end

  xxit 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10b',
    )
  end

  xxit 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10c',
    )
  end

  xxit 'Q10d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10d',
    )
  end

  xxit 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q11',
    )
  end

  xxit 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q12a',
    )
  end

  xxit 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q12b',
    )
  end

  xxit 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13a1',
    )
  end

  xxit 'Q13b1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13b1',
    )
  end

  xxit 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13c1',
    )
  end

  xxit 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q14a',
    )
  end

  xxit 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q14b',
    )
  end

  xxit 'Q15' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q15',
    )
  end

  xxit 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q16',
    )
  end

  xxit 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q17',
    )
  end

  xxit 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q19b',
    )
  end

  xxit 'Q20a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q20a',
    )
  end

  xxit 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q21',
    )
  end

  xxit 'Q22a2' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22a2',
    )
  end

  xxit 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22c',
    )
  end

  xxit 'Q22d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22d',
    )
  end

  xxit 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22e',
    )
  end

  xxit 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q23c',
    )
  end

  xxit 'Q24' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q24',
    )
  end

  xxit 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q25a',
    )
  end

  xxit 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q26b',
    )
  end
end
