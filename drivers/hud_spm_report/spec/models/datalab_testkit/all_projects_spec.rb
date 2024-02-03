###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'spm_context'

RSpec.describe 'Datalab Testkit SPM All-Projects', type: :model do
  include_context 'datalab testkit context'
  include_context 'datalab spm context'

  # NOTE: disabling all SPM tests for now, they are not compatible with the current test kit source data.

  # Only run the tests if the source files are available
  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    before(:all) do
      puts "Starting SPM Data Lab TestKit #{Time.current}"
      setup
      puts "Setup Done for SPM Data Lab TestKit #{Time.current}"
      # run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys.grep(/Measure (3|4|5|7)/))
      run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    # Almost matches (off by a few)
    xit 'Measure 1a' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        external_column_header: true,
        external_row_label: true,
        question: '1a',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 1b' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        external_column_header: true,
        external_row_label: true,
        question: '1b',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 2' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '2',
      )
    end

    # Almost matches (off by a few)
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

    # Almost matches (off by a few)
    xit 'Measure 4.4' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '4.4',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 4.5' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '4.5',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 4.6' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '4.6',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 5.1' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '5.1',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 5.2' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '5.2',
      )
    end

    it 'Measure 7a.1' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '7a.1',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 7b.1' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '7b.1',
      )
    end

    # Almost matches (off by a few)
    xit 'Measure 7b.2' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '7b.2',
      )
    end
  else
    xit 'Data Lab Testkit based tests are skipped, files are missing' do
    end
  end
end
