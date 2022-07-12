###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'spm_context'

RSpec.describe 'Datalab Testkit SPM All-Projects', type: :model do
  include_context 'datalab testkit context'
  include_context 'datalab spm context'

  before(:all) do
    puts "Starting SPM Data Lab TestKit #{Time.current}"
    setup
    puts "Setup Done for SPM Data Lab TestKit #{Time.current}"
    run(default_spm_filter, HudSpmReport::Generators::Fy2020::Generator.questions.keys)
    puts "Finished SPM Run Data Lab TestKit #{Time.current}"
  end

  xit 'Measure 1a' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '1a',
    )
  end

  xit 'Measure 1b' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '1b',
    )
  end

  xit 'Measure 2' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '2',
    )
  end

  xit 'Measure 3.2' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '3.2',
    )
  end

  it 'Measure 4.1' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.1',
    )
  end

  it 'Measure 4.2' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.2',
    )
  end
  it 'Measure 4.3' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.3',
    )
  end
  it 'Measure 4.4' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.4',
    )
  end
  it 'Measure 4.5' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.5',
    )
  end
  it 'Measure 4.6' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '4.6',
    )
  end

  xit 'Measure 5.1' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '5.1',
    )
  end

  xit 'Measure 5.2' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '5.2',
    )
  end

  xit 'Measure 7a.1' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '7a.1',
    )
  end

  xit 'Measure 7b.1' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '7b.1',
    )
  end

  xit 'Measure 7b.2' do
    compare_results(
      file_path: result_file_prefix + 'spm',
      question: '7b.2',
    )
  end
end
