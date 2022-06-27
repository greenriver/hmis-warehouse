###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'datalab_caper_context'

RSpec.describe 'Datalab 2021 CAPER - NBN ES', type: :model do
  include_context 'datalab caper context'

  before(:all) do
    setup
    run(es_nbm_filter)
  end

  after(:all) do
    cleanup
  end

  it 'Q4a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q4a',
      skip: [
        'B2', # expected is a name not and ID?
        'L2', # Is the generator name, so not expected to match
      ],
    )
  end

  it 'Q5a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q5a',
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6a',
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6b',
    )
  end

  it 'Q6c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6c',
    )
  end

  it 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6d',
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6e',
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6f',
      skip: [ # AAQ pending
        'B2',
        'C2',
        'D2',
      ],
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q7a',
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q7b',
      skip: [ # pending AAQ
        'B5',
        'D5',
        'F5',
      ],
    )
  end

  it 'Q8a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q8a',
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q8b',
    )
  end

  it 'Q9a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q9a',
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q9b',
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10a',
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10b',
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10c',
    )
  end

  it 'Q10d' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10d',
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q11',
    )
  end

  it 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q12a',
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q12b',
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q13a1',
    )
  end

  it 'Q13b1' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q13b1',
    )
  end

  it 'Q13c1' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q13c1',
    )
  end

  it 'Q14a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q14a',
    )
  end

  it 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q14b',
    )
  end

  it 'Q15' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q16',
      skip: [ # pending AAQ
        'C7',
        'C12',
      ],
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q17',
      skip: [ # pending AAQ
        'C17',
      ],
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q19b',
    )
  end

  it 'Q20a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q20a',
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q21',
    )
  end

  xit 'Q22a2' do # pending AAQ
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22a2',
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22c',
    )
  end

  xit 'Q22d' do # pending AAQ
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22d',
    )
  end

  # FIXME: this should be re-enabled when the new data set is implemented
  xit 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22e',
    )
  end

  it 'Q23c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q23c',
    )
  end

  it 'Q24' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q24',
    )
  end

  it 'Q25a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q25a',
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q26b',
    )
  end
end
