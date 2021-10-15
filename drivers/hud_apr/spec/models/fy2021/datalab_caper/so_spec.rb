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

  xit 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q5a',
    )
  end

  xit 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6a',
    )
  end

  xit 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6b',
    )
  end

  xit 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6c',
    )
  end

  xit 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6d',
    )
  end

  xit 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6e',
    )
  end

  xit 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q6f',
    )
  end

  xit 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q7a',
    )
  end

  xit 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q7b',
    )
  end

  xit 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q8a',
    )
  end

  xit 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q8b',
    )
  end

  xit 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q9a',
    )
  end

  xit 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q9b',
    )
  end

  xit 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10a',
    )
  end

  xit 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10b',
    )
  end

  xit 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10c',
    )
  end

  xit 'Q10d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q10d',
    )
  end

  xit 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q11',
    )
  end

  xit 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q12a',
    )
  end

  xit 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q12b',
    )
  end

  xit 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13a1',
    )
  end

  xit 'Q13b1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13b1',
    )
  end

  xit 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q13c1',
    )
  end

  xit 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q14a',
    )
  end

  xit 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q14b',
    )
  end

  xit 'Q15' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q15',
    )
  end

  xit 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q16',
    )
  end

  xit 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q17',
    )
  end

  xit 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q19b',
    )
  end

  xit 'Q20a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q20a',
    )
  end

  xit 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q21',
    )
  end

  xit 'Q22a2' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22a2',
    )
  end

  xit 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22c',
    )
  end

  xit 'Q22d' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22d',
    )
  end

  xit 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q22e',
    )
  end

  xit 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q23c',
    )
  end

  xit 'Q24' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q24',
    )
  end

  xit 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q25a',
    )
  end

  xit 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'so',
      question: 'Q26b',
    )
  end
end
