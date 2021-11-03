###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
      skip: [
        'B1', # FIXME
        'B2', # FIXME
        'B3', # FIXME
        'B4', # FIXME
        'B5', # FIXME
        'B6', # FIXME
        'B7', # FIXME
        'B8', # FIXME
        'B10', # FIXME
        'B12', # FIXME
        'B13', # FIXME
        'B14', # FIXME
        'B15', # FIXME
        'B16', # FIXME
      ],
    )
  end

  it 'Q6a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6a',
      skip: [
        'B2', # FIXME
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
        'E5', # FIXME
        'F5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'E7', # FIXME
        'F7', # FIXME
        'E8', # FIXME
        'F8', # FIXME
      ],
    )
  end

  it 'Q6b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6b',
      skip: [
        'B2', # FIXME
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
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6c',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'B5', # FIXME
        'C5', # FIXME
      ],
    )
  end

  it 'Q6d' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6d',
      skip: [
        'B2', # FIXME
        'E2', # FIXME
        'F2', # FIXME
        'G2', # FIXME
        'H2', # FIXME
        'B5', # FIXME
        'H5', # FIXME
      ],
    )
  end

  it 'Q6e' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6e',
      skip: [
        'C2', # FIXME
        'B6', # FIXME
        'C6', # FIXME
      ],
    )
  end

  it 'Q6f' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q6f',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'C3', # FIXME
      ],
    )
  end

  it 'Q7a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q7a',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'B5', # FIXME
        'F5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
      ],
    )
  end

  it 'Q7b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
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
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q8a',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'F2', # FIXME
      ],
    )
  end

  it 'Q8b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
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
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q9a',
      skip: [
        'B2', # FIXME
        'E2', # FIXME
        'B6', # FIXME
        'E6', # FIXME
      ],
    )
  end

  it 'Q9b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q9b',
      skip: [
        'B2', # FIXME
        'E2', # FIXME
        'B6', # FIXME
        'E6', # FIXME
        'B7', # FIXME
        'E7', # FIXME
      ],
    )
  end

  it 'Q10a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10a',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'D9', # FIXME
      ],
    )
  end

  it 'Q10b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10b',
      skip: [
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'D9', # FIXME
      ],
    )
  end

  it 'Q10c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10c',
      skip: [
        'B8', # FIXME
        'F8', # FIXME
        'B9', # FIXME
        'F9', # FIXME
      ],
    )
  end

  it 'Q10d' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q10d',
      skip: [
        'B2', # FIXME
        'E2', # FIXME
        'B3', # FIXME
        'E3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'E4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'E5', # FIXME
        'F5', # FIXME
        'B6', # FIXME
        'E6', # FIXME
        'B7', # FIXME
        'E7', # FIXME
        'B8', # FIXME
        'E8', # FIXME
        'H8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'D9', # FIXME
        'E9', # FIXME
        'F9', # FIXME
        'H9', # FIXME
      ],
    )
  end

  it 'Q11' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q11',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'B4', # FIXME
        'E4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'D7', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'B12', # FIXME
        'F12', # FIXME
        'B13', # FIXME
        'C13', # FIXME
        'D13', # FIXME
        'E13', # FIXME
        'F13', # FIXME
      ],
    )
  end

  it 'Q12a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q12a',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'D7', # FIXME
        'E7', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'F9', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'D10', # FIXME
        'E10', # FIXME
        'F10', # FIXME
      ],
    )
  end

  it 'Q12b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q12b',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'F5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
      ],
    )
  end

  it 'Q13a1' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q13a1',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'E5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'D8', # FIXME
        'E8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'D9', # FIXME
        'E9', # FIXME
      ],
    )
  end

  it 'Q13b1' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q13b1',
      skip: [
        'B2', # FIXME
        'C2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'B3', # FIXME
        'C3', # FIXME
        'F3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'E5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'D8', # FIXME
        'E8', # FIXME
        'B9', # FIXME
        'C9', # FIXME
        'D9', # FIXME
        'E9', # FIXME
      ],
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
        'F5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
      ],
    )
  end

  it 'Q14b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
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

  xit 'Q15' do # FIXME
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q15',
    )
  end

  it 'Q16' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q16',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B14', # FIXME
        'D14', # FIXME
      ],
    )
  end

  it 'Q17' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q17',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'B4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B9', # FIXME
        'D9', # FIXME
        'B11', # FIXME
        'D11', # FIXME
        'B12', # FIXME
        'D12', # FIXME
        'B13', # FIXME
        'D13', # FIXME
        'D14', # FIXME
        'B15', # FIXME
        'D15', # FIXME
        'B16', # FIXME
        'D16', # FIXME
        'D17', # FIXME
      ],
    )
  end

  it 'Q19b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q19b',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'E2', # FIXME
        'G2', # FIXME
        'H2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F4', # FIXME
        'H4', # FIXME
        'I4', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'E7', # FIXME
        'C9', # FIXME
        'D9', # FIXME
        'C10', # FIXME
        'D10', # FIXME
        'G10', # FIXME
        'H10', # FIXME
        'G11', # FIXME
        'H11', # FIXME
        'C12', # FIXME
        'D12', # FIXME
        'G12', # FIXME
        'H12', # FIXME
        'C13', # FIXME
        'D13', # FIXME
        'G13', # FIXME
        'H13', # FIXME
        'B14', # FIXME
        'C14', # FIXME
        'D14', # FIXME
        'F14', # FIXME
        'G14', # FIXME
        'H14', # FIXME
      ],
    )
  end

  it 'Q20a' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q20a',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B7', # FIXME
        'D7', # FIXME
      ],
    )
  end

  it 'Q21' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q21',
      skip: [
        'B2', # FIXME
        'D2', # FIXME
        'B3', # FIXME
        'D3', # FIXME
        'B4', # FIXME
        'D4', # FIXME
        'B6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'D7', # FIXME
        'B8', # FIXME
        'D8', # FIXME
        'B9', # FIXME
        'D9', # FIXME
        'B12', # FIXME
        'D12', # FIXME
        'B13', # FIXME
        'D13', # FIXME
        'B14', # FIXME
        'C14', # FIXME
        'D14', # FIXME
        'B16', # FIXME
        'D16', # FIXME
        'B17', # FIXME
        'D17', # FIXME
      ],
    )
  end

  it 'Q22a2' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22a2',
      skip: [
        'B5', # FIXME
        'C5', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'D10', # FIXME
        'B16', # FIXME
        'C16', # FIXME
        'D16', # FIXME
      ],
    )
  end

  it 'Q22c' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22c',
    )
  end

  it 'Q22d' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22d',
      skip: [
        'B5', # FIXME
        'D5', # FIXME
        'B8', # FIXME
        'D8', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'D10', # FIXME
        'E10', # FIXME
        'F10', # FIXME
        'B16', # FIXME
        'C16', # FIXME
        'D16', # FIXME
        'E16', # FIXME
        'F16', # FIXME
      ],
    )
  end

  it 'Q22e' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q22e',
      skip: [
        'B4', # FIXME
        'E4', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'D7', # FIXME
        'B8', # FIXME
        'C8', # FIXME
        'D8', # FIXME
        'B9', # FIXME
        'D9', # FIXME
        'E9', # FIXME
        'B10', # FIXME
        'C10', # FIXME
        'B11', # FIXME
        'C11', # FIXME
        'D11', # FIXME
        'E11', # FIXME
        'F11', # FIXME
        'B12', # FIXME
        'C12', # FIXME
        'B13', # FIXME
        'C13', # FIXME
        'D13', # FIXME
        'E13', # FIXME
        'F13', # FIXME
        'B14', # FIXME
        'C14', # FIXME
        'D14', # FIXME
        'E14', # FIXME
        'F14', # FIXME
      ],
    )
  end

  xit 'Q23c' do # FIXME
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
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'B4', # FIXME
        'C4', # FIXME
        'D4', # FIXME
        'B5', # FIXME
        'D5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'B7', # FIXME
        'C7', # FIXME
        'D7', # FIXME
      ],
    )
  end

  it 'Q26b' do
    compare_results(
      file_path: result_file_prefix + 'es_nbn',
      question: 'Q26b',
      skip: [
        'B3', # FIXME
        'C3', # FIXME
        'D3', # FIXME
        'E3', # FIXME
        'F3', # FIXME
        'B5', # FIXME
        'C5', # FIXME
        'B6', # FIXME
        'C6', # FIXME
        'D6', # FIXME
        'E6', # FIXME
        'F6', # FIXME
      ],
    )
  end
end
